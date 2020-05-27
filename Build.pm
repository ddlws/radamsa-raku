class Build {
    method build($dist-path) {
        my $d = $dist-path~'/radamsa';
        #unless $d.IO ~~ :e {
            #shell('git clone --single-branch --branch develop https://gitlab.com/akihe/radamsa.git');
        #}
        unless ($d~'/lib/libradamsa.so').IO ~~ :e {
            indir('radamsa',{shell('make lib/libradamsa.so')});
        }
        shell('mkdir -p resources/lib');
        shell('mv '~"radamsa/lib/libradamsa.so resources/lib/libradamsa.so");
        return 1;
    }
}
