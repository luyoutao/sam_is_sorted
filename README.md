## Summary:
 Test whether a SAM/BAM is coordinate/queryname sorted. It outputs 'true' if sorted, 'false' if not, and 'unknown' if cannot decide.
 
## Usage:
    perl sam_is_sorted.pl -i input.[sam|bam] [--name] [--header_only] [-v] [-h] [--debug info]
    
## Options:
    --input, -i     input BAM/SAM;
    --name, -n      whether queryname sorted. If missing, defaults to testing whether coordinate sorted;
    --header_only   determine only by the header's 'SO' field in @HD. If no header, outputs 'unknown' and exit with -1.

## Examples:
    perl sam_is_sorted.pl -i test/nameSorted.bam -n
    [2021-07-17 19:54:11.049 -0400] {VERSION = 0.4, name = 1, header_only = 0, help = 0, version = 0, debug = info}
    true

    $ perl sam_is_sorted.pl -i test/nameSorted.bam 
    [2021-07-17 19:51:19.043 -0400] {VERSION = 0.4, name = 0, header_only = 0, help = 0, version = 0, debug = info}
    [2021-07-17 19:51:19.052 -0400] Unsorted records: prev = chr3:73635965, next = chr3:73635859
    false

    $ perl sam_is_sorted.pl -i test/posSorted.bam 
    [2021-07-17 19:51:28.450 -0400] {VERSION = 0.4, name = 0, header_only = 0, help = 0, version = 0, debug = info}
    true
    
    $ perl sam_is_sorted.pl -i test/posSorted.bam -n
    [2021-07-17 19:52:10.865 -0400] {VERSION = 0.4, name = 1, header_only = 0, help = 0, version = 0, debug = info}
    [2021-07-17 19:52:10.873 -0400] Unsorted records: prev = NB501328:230:HCG23BGXB:1:11101:18429:13938, next = NB501328:230:HCG23BGXB:1:11101:2941:13994
    false
