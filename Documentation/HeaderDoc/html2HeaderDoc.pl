#!/usr/bin/perl
# $Id$
# Script to create HeaderDoc comments from NeXT documentation
# converted from RTF to HTML.
# Leigh Smith <leigh@tomandandy.com>
#
# NeXT RTF doco file consists of:
#  CLASS DESCRIPTION
#  description
#  MEMORY SPACES
#  description
#  INSTANCE VARIABLES
#  CLASS METHODS
#  name which must match first word of prototype.
#  + prototype
#  \n\n
#  description
#  INSTANCE METHODS
#  name which must match first word of prototype.
#  - prototype
#  \n\n
#  description
#  PARAMETER INTERPRETATION
#  part of class description
#  EOF
#
# A method consists of a prototype followed by its description (discussion).
#
# headerDoc expects the copyright to be placed in a configuration
# file: headerDoc2HTML.config in the cwd. We use that for the
# copyright statement.
#
# We write the output either as a header file with only comments, or
# as a sed script to run over the existing .h file to merge the new
# comments in.
# Sed scripts look like:
# /- *methodName:/i\
# \
# /*\
# New header\
# */
$nameMethods="method";		# or "function".

eval 'exec /usr/bin/perl -S $0 ${1+"$@"}' if $running_under_some_shell;

while ($ARGV[0] =~ /^-/) {
    $_ = shift;
    last if /^--/;
    if (/^-n/) {
	$printMissing++;
	next;
    }
    elsif (/^-s/) {
	$sedOutput++;
	next;
    }
    elsif (/^-d/) {
	$debug++;
	next;
    }
    die "I don't recognize this switch: $_\\n";
}

if($sedOutput) {
    $eolChar = "\\";		# add a backslash and newline on print
}

$\ = "\n";			# automatically add newline on print

# get Class name from filename
$ARGV[0] =~ /\/([^\/]*?)\.html/;
$classname = $1;

# Since HTML doesn't interpret \n as formatting, we read the entire
# file into memory, replacing \n's with spaces.
while (chop($_ = <>)) {
    #
    # Here we remove wierd HTML cruft.
    #
    # remove <div></div> tags
    s/<div[^>]*>//g;
    s/<\/div>//g;
    # and wierd space characters
    s/&#8364;/ /g;
    # and wierd not signs indicating RTF images.
    s/&#172;//g;
    # For some reason, elongated hyphens were sometimes used for '-'.
    s/&#177;/-/g;

    # Convert numeric left and right double quotes into their symbolic entities.
    s/&#170;/&ldquo;/g;
    s/&#186;/&rdquo;/g;

    # Any HTML with spaces before closure of a tag is usually from a
    # misplaced bold or italic in the original RTF and needs swapping.
    s/(\s+)(<\/[a-zA-Z0-9]+>)/\2\1/g;

    # move any leading space before an end tag i.e 
    # <b>Text with trailing space </b>
    s/(  *)<\/(.*)>/<\/$2>$1/g;

    # substitute wierd German characters for hyphens between text.
    s/&ETH;/ - /g;
    # This checks if any page breaks divide a section title.
    $wholeFile = $wholeFile . " " . $_;
}

# Synthpatches have parameter descriptions at the end of the file.
if($wholeFile =~ s/Parameter Interpretation(.*?)$//i) {
    $parameterInterpretation = $1;
}

# UnitGenerators have a Memory Spaces section that needs to be
# incorporated into the discussion
if($wholeFile =~ s/Memory Spaces(.*?)(Instance Methods|Class Methods)/\2/i) {
    $memorySpaces = $1;
}

# Check for class header, if so, generate a @discussion tag
if ($wholeFile =~ s/^.*?Class Description(.*?)(Instance Variables|Method Types|Instance Methods|Class Methods)/\2/i) {
    $description = $1;
    if($sedOutput) {
	printf("1i\\\n");
    }
    printf("/*!%s\n  \@class $classname%s\n  \@abstract%s\n  \@discussion%s\n", $eolChar, $eolChar, $eolChar, $eolChar);

    # Substitute any .eps files to be a figure
    $description =~ s/([^>\s]+)\.eps/\<img src=\"Images\/$1.gif\">/;
    
    if(length($parameterInterpretation) != 0) {
	$description .= "<h2>Parameter Interpretation</h2>". $parameterInterpretation;
    }
    if(length($memorySpaces) != 0) {
	$description .= "<h2>Memory Spaces</h2>" . $memorySpaces;
    }
    # output the text of the description
    # compact more than two consecutive \n's to a single one.
    $description =~ s/(<br>\s*){3,}/<br><br>/g;
    # convert HTML page breaks to standard EOLs (HeaderDoc generates its own).
    $description =~ s/<br>/\n/g;
    printf("%s\n*/\n", lineWrap($description, 80, ""));
}
    
# Remove the methods listed in the Method Types section
# Retain the instance variables listed in that section as occasionally
# it will have some human created description.
if($wholeFile =~ s/Instance Variables(.*?)Method Types(.*?)(Instance|Class) Methods//i) {
    $ivarDescription = $1;
}

# We can remove the Instance Method title
$wholeFile =~ s/Instance Methods//i;

# Prefix each method definition with HeaderDoc opening.
# find the +/-, the method prototype and the discussion. 
#
# Look for a non-blank string of characters, possibly
# terminated with a colon that indicates this is the preluding
# method title to the next prototype, effectively the end of the
# description.
#
# We rewrite this as a <br> to ensure we don't break other prototype
# boundaries.
while ($wholeFile =~ s/<br>\s*(<b>)*\s*([\+\-])\s*(<\/b>)*\s*(.*?)(<br>\s*){2,}(.*?)(<br>\s*)+(<br>\S+<br>|<br>\s|<br><b>\s|<br>$)/<br>/) {
    $leadingBold = $1;
    $classOrInstanceMethod = $2;
    $prototype = $4;
    $lineBreaksBetweenPrototypeAndDiscussion = $5;
    $discussion = $6;
    $lineBreaksBetweenDiscussionAndNextPrototype = "first break=\"$7\" second break=\"$8\"";
    $formattedPrototype = $classOrInstanceMethod . $prototype;
    # give ourselves a clean description
    # $formattedPrototype =~ s/<\/*[bi]>//g;

    if($debug) {
	print "leading bold attribute = \"$leadingBold\"";
	print "method type = $classOrInstanceMethod prototype for matching = $prototype\n";
	print "line breaks between prototype and discussion = $lineBreaksBetweenPrototypeAndDiscussion\n";
	print "discussion = $discussion\n";
	print "line breaks between discussion and next prototype = $lineBreaksBetweenDiscussionAndNextPrototype\n";
    }
    # If we had a leading bold attribute case, we need to prepend it
    # to the prototype so that it is parseable.
    if($leadingBold =~ m/<b>\s*/) {
	# print "prepending leading bold attribute\n";
	$prototype = "<b>" . $prototype;
    }
    # Format the prototype for HeaderDoc.
    # Match the return type and the method name prior to parameters.
    if ($prototype =~ s/\s*(\(.*?\)|[^\s<]*?)\s*<b>\s*(.*?)\s*<\/b>//) {
	$returnType = $1;
	$methodName = $2;  # The start of the method name.
	# blow away any parentheses, in theory I can do it in the
	# previous regexp, but I haven't achieved that astral plane yet...
	$returnType =~ s/[\(\)]//g;

	$paramCount = 0;
	# Keep sucking out parameters, or until we obviously have
	# something we can't digest, spit it out.
	while(($prototype !~ /^\s*$/) && ($paramCount != 15)) {
	    if($debug) {
		print "methodName = $methodName\nprototype remaining: $prototype";
	    }
	    # Match on parameter type (some won't be static)...
	    # Ensure an italicized parameter doesn't precede the type
	    # (indicating we have missed an untyped (i.e id) parameter).
	    if ($prototype =~ s/^\s*\((.*?)\)//) {
		$paramType[$paramCount] = $1;
	    }
	    else {
		$paramType[$paramCount] = "id";
	    }

	    # ...and parameter name
	    if ($prototype =~ s/\s*<i>\s*([^\s]*?)\s*<\/i>//) {
		$paramName[$paramCount] = $1;
	    }
	    
	    # ...and wierd cruft like trailing semicolons, invisible
	    # italics and bolding...arrggh!
	    $prototype =~ s/;//;
	    $prototype =~ s/<b>\s*<\/b>//;
	    $prototype =~ s/<i>\s*<\/i>//;
            $prototype =~ s/<br>//;

	    # ...and subsequent 'keyName:' keywords
	    if ($prototype =~ s/\s*((<b>\s*)|())(.*?:)\s*((<\/b>)|())//) {
		$methodName .= $4;
	    }
	    $paramCount++;
	}
	if($paramCount >= 15 && !$sedOutput) {
	    # if we hit an undigestible morsel.
	    print "Couldn't eat \"$prototype\" - bleuch!\n";
	}
    }
    
    # print out what we found, possibly as a sed script
    if($sedOutput) {
	if ($returnType ne "") {
	    # if return type is id, allow id or nothing, since it
	    # is the default type.
	    if ($returnType eq "id") {
		$sedReturnType = "(* *i*d* *)*";
	    }
	    else {
		$sedReturnType = $returnType;
		$sedReturnType =~ s/\*/\\*/g;
		$sedReturnType = "\( *$sedReturnType *\)";
		# preserve any pointers, don't make them wild cards.
	    }
	}
	else {
	    $sedReturnType = "";
	}
	$sedMethodName = $methodName;
	# ensure methodName and methodNameLongerVersion are not confused
	$sedMethodName =~ s/([^:])$/\1 *; */;
	# distinguish between  methodName: and methodName:extraParam:
	$sedMethodName =~ s/:/:[^:]* */g;
	# anchor the search to ensure substrings are not found.
	$sedMethodName .= "\$";
	# ensure method starts at beginning of line (avoids problems
	# with prototypes in comments). Really we should do something
	# to avoid doing searches within C comments, but that can be
	# hard to do in sed.
	printf("/^%s *%s *%s/i\\\n\\\n", $classOrInstanceMethod, $sedReturnType, $sedMethodName);
	$commentPadding = "\\ \\ ";
    }
    else {
	$commentPadding = "  ";
    }
    printf("/*!%s\n", $eolChar); 

    printf("%s\@%s %s%s\n", $commentPadding, $nameMethods, $methodName, $eolChar);
    for($i = 0; $i < $paramCount; $i++) {
	# no return type defaults to id.
	if (length($paramType[$i]) == 0) {
	    $paramType[$i] = "id";
	}
	printf("%s\@param  %s is %s %s.%s\n", $commentPadding,
	       $paramName[$i], indefiniteArticle($paramType[$i]), $paramType[$i],
	       $eolChar); 
	$paramType[$i] = $paramName[$i] = "";
    }
    
    # no return type defaults to id.
    if (length($returnType) == 0) {
	$returnType = "id";
    }

    # Do MK prefixing of common classes
    $discussion =~ s/(\W)UnitGenerator/\1MKUnitGenerator/g;
    $discussion =~ s/(\W)SynthPatch/\1MKSynthPatch/g;
    $discussion =~ s/(\W)Envelope/\1MKEnvelope/g;

    # Attempt to make the return type slightly more readable, checking
    # if we mention returning self in the discussion, if so, replacing
    # id in the result and removing the statement in the discussion..
    if ($discussion =~ s/Returns <b>self<\/b>\.//) {
	$returnType = "<b>self</b>";
	$indefiniteArticle = "";
    }
    else {
	$indefiniteArticle = indefiniteArticle($returnType) . " ";
    }
    if ($returnType ne "void") {
	printf("%s\@result Returns %s%s.%s\n", $commentPadding,
	       $indefiniteArticle, $returnType, $eolChar);
    }

    # convert <br>'s to standard line breaks for headerDoc to do it's stuff.
    $discussion =~ s/<br>/\n/g;
    printf("%s\@discussion %s%s\n*/\n", $commentPadding,
	   lineWrap($discussion, 68, $commentPadding . "            "));
}

# print what was not accounted for for debugging.
if ($printMissing) { 
    print STDERR "remaining data not accounted for: $wholeFile";
}

# Determine whether to prefix the word with an "a" or an "an".
sub indefiniteArticle
{
    return (index("aeiouh", substr($_[0],0,1)) == -1) ? "a" : "an";
}

# Reformat the string to a maximum of lineWidth with a prefix padding
# the line.
sub lineWrap
{
    local($longString, $lineWidth, $padding) = @_;
    local($formattedString);
    local($minWidth) = $lineWidth - 20;
    
    # print "longString before any change: $longString\n(end of longstring)\n";
    $longString =~ s/\n/$eolChar\n$padding/sg;
    do {
	# print "longstring = $longString\n";
	# print "formattedString = $formattedString\n";
	while($longString =~ s/^([^\n\\]{$minWidth,$lineWidth})\s//s) {
	    $formattedString .= $1 . $eolChar . "\n" . $padding;
	}
	$longString =~ s/^(.*?)(\n|$)//s;
	if($2 eq "\n") {
	    $formattedString .= $1 . "\n";
	}
	else {
	    $formattedString .= $1;
	}
    } while(length($longString) > $lineWidth);
    return $formattedString . $longString . $eolChar;
}
