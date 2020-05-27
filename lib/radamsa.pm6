use NativeCall;
constant \libradamsa = %?RESOURCES{'lib/libradamsa.so'};
sub _radamsa_init() is native(libradamsa) is symbol('radamsa_init') is export {*}
sub _radamsa(buf8 $ptr is rw, size_t $len, buf8 $target is rw, size_t $max, uint32 $seed) is native(libradamsa) is symbol('radamsa') returns size_t is export {*}
sub _radamsa_inplace(uint8 $ptr is rw, size_t $len, size_t $max, uint32 $seed) is native(libradamsa) is symbol('radamsa_inplace') returns size_t is export {*}

class radamsa is Channel {
    has @.inputs is rw;
    has uint64 $.maxoutsz is rw;
    has uint $.minqsz is rw = 100;
    has atomicint $.count;
    has uint32 $!seed;
    method send(Channel:D: \item --> Nil) { $!count⚛++; callsame; }
    method receive(Channel:D:) { $!count⚛--; callsame; }
    method getcount() { return ⚛$!count; }

    submethod TWEAK() {
        _radamsa_init();
        $!seed = (0xffffffff).rand.Int;

        unless ?$!maxoutsz { $!maxoutsz = @!inputs.sort[*-1].elems; }
    }

    multi method new(Str $s, *%we) {
        my buf8 $b .= new(|$s.encode);
        self.bless( :inputs(($b)), |%we);
    }

    multi method new(IO::Path $p, *%we) {
        self.bless(:inputs(self.read-dir-inputs($p)), |%we);
    }
    multi method new(buf8 @inputs, *%we) {
        self.bless(:@inputs, |%we);
    }

    #| returns a single candidate
    method gen1(--> buf8) {
        my Blob $b = @!inputs.pick;
        my Blob $out = buf8.allocate($!maxoutsz,0);
        my $sz = _radamsa($b, $b.elems, $out, $!maxoutsz, $!seed++);
        return $out.subbuf(0,$sz);
    }

    #| starts emitting over the channel
    method startchannel() { start { self!radworker() } }

    method !radworker() {
        my $c = ⚛$!count;
        my Blob $out = buf8.allocate($!maxoutsz,0);
        loop {
            NEXT { $c = ⚛$!count;
                if $c < .1 * $!minqsz { $!minqsz = ($!minqsz * 1.1).floor; }
            }
            for ^($!minqsz - $c) {
                my Blob $b = @!inputs.pick;
                my $sz = _radamsa($b, $b.elems, $out, $!maxoutsz, $!seed++);
                self.send( $out.subbuf(0,$sz) );
            }
        }
    }
    multi method addinput(Blob $b) { @!inputs.push($b); }
    multi method addinput(Str $s) { @!inputs.push(buf8.new(|$s.encode)); }
    multi method addinput(IO::Path $p) { @!inputs.append(self.read-dir-inputs($p)); }
    method read-dir-inputs(IO::Path $p) {
        my @inputs;
        #dirs
        if $p ~~ :d {
            for $p.dir {
                #push it if it's a readable file
                @inputs.push( $_.slurp(:bin)) if $_ ~~ :f & :r;
                #recurse if it's a directory
                @inputs.append(self.read-dir-inputs($_)) if $_ ~~ :d;
            }
        }
        #files
        if $p ~~ :!d & :r { @inputs.push($_.slurp(:bin)); }

        return @inputs;

    }
}
