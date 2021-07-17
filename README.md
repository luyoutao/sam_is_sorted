## Summary:
 Test whether a SAM/BAM is coordinate/queryname sorted. It outputs 'true' if sorted, 'false' if not, and 'unknown' if cannot decide.
 
## Usage:
    perl sam_is_sorted.pl -i input.[sam|bam] [--name] [--header_only] [-v] [-h] [--debug info]
    
## Options:
    --input, -i     input BAM/SAM;
    --name, -n      whether queryname sorted. If missing, defaults to testing whether coordinate sorted;
    --header_only   determine only by the header's 'SO' field in @HD. If no header, outputs 'unknown' and exit with -1.
