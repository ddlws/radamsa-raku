class Build {
    method build($dist-path) {
        my $d = $dist-path~'/radamsa';
        unless $d.IO ~~ :e {
            shell('git clone --single-branch --branch develop https://gitlab.com/akihe/radamsa.git');
        }
        indir($d, {shell('git checkout 9f83001c6dc43c1d62afa9282e10206062657e97')});
        indir($d,{shell('make lib/libradamsa.so')});
        shell('mkdir -p resources/lib');
        shell('mv '~"radamsa/lib/libradamsa.so resources/lib/libradamsa.so");
        return 1;
    }
}
