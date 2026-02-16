
#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<EOF
Usage: $0 <input.ics> <pattern> [output.ics]

	<input.ics>   : path to the .ics file to filter
	<pattern>     : single REGEX to match event titles (use '|' for alternatives)
									example: "Meeting|Conférence|Workshop"
									(match mode : contain)
	[output.ics]  : optional output file path (defaults to input path with _filtered suffix)
EOF
	exit 2
}

if [[ ${1:-} == "" || ${2:-} == "" ]]; then
	usage
fi

input="$1"
pattern="$2"
output="${3:-}"

if [[ ! -f "$input" ]]; then
	echo "Fichier introuvable: $input" >&2
	exit 1
fi

if [[ -z "$output" ]]; then
	# create default output: add _filtered before extension or at end
	if [[ "$input" == *.* ]]; then
		base="${input%.*}"
		ext="${input##*.}"
		output="${base}_filtered.${ext}"
	else
		output="${input}_filtered"
	fi
fi

tmpf="$(mktemp "${output}.XXXXXX")"
trap 'rm -f "$tmpf"' EXIT

# Use Perl to: preserve everything outside VEVENT blocks, filter VEVENT blocks
# by matching the unfolded SUMMARY against the provided pattern.
PATTERN="$pattern"
PATTERN_ESCAPED="$PATTERN"

PERL_SCRIPT=''
PERL_SCRIPT+='my $p = $ENV{PATTERN} // die "Missing PATTERN\n";'
PERL_SCRIPT+='local $/; my $text = <>;'
PERL_SCRIPT+='my ($header) = ($text =~ /(.*?)(?=BEGIN:VEVENT)/s); $header = "" unless defined $header; $header =~ s/\s+\z/\n/; print $header;'
PERL_SCRIPT+='my @events = ($text =~ /(BEGIN:VEVENT.*?END:VEVENT)/sg);'
PERL_SCRIPT+='for my $blk (@events) { my $blk2 = $blk; $blk2 =~ s/\r?\n[ \t]//g; my $summary = ""; if ($blk2 =~ /SUMMARY:(.*?)(?:\r?\n|\z)/i) { $summary = $1 } if ($summary =~ /$p/i) { print $blk; print "\n" unless $blk =~ /\r?\n\z/ } }'
PERL_SCRIPT+='my $footer = ""; if ($text =~ /END:VEVENT.*\z/s) { my $pos = rindex($text, "END:VEVENT"); $footer = substr($text, $pos + length("END:VEVENT")); } $footer = "\n" . $footer if $footer ne "" && $footer !~ /^\r?\n/; print $footer;'

export PATTERN
perl -0777 -e "$PERL_SCRIPT" -- "$input" > "$tmpf"

mv "$tmpf" "$output"
trap - EXIT
echo "Écrit: $output"

