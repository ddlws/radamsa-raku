radamsa
====================================

Raku bindings for radamsa, a general purpose fuzzer https://gitlab.com/akihe/radamsa

When you have to start fuzzing RIGHT NOW, radamsa is hard to beat. However, hidden under a mountain of parentheses in the radamsa git repo is real black magic, libradamsa, which is what these bindings are actually for. This is multithreaded fuzzing on easy mode.

### Installation

> `zef install Radamsa`

The build fetches radamsa source from https://gitlab.com/akihe/radamsa and builds libradamsa.so. It'll take a minute.

### Using it

`use Radamsa;`

There is one class, `radamsa`. You'll need to initialize it with good input(s).

There are three convenience constructors:

__`new(Str $s)`__

seeds radamsa with a single string

> `my $r = radamsa.new("fuzz me");`

__`new(IO::Path $p)`__

If `$p` is a file, then `$p`'s contents are the seed. If `$p` is a directory, radamsa adds every file and recurses through subdirectories. Use this to fuzz file formats.

__`new(buf8 @inputs)`__

Inputs are stored as an array of `buf8`s, so this sets it directly.

> `my $r = radamsa.new(@arrayofbuf8s);`

#### Optional parameters
__`:maxoutsz`__
This sets a byte limit for the length of radamsa's output. If you don't specify it, radamsa will set it to the length of the longest input provided to the constructor.

__`:minqsz`__

Radamsa tries to avoid idle workers by keeping a minimum number of ouputs in the queue. More detail is provided below. You can ignore this.

### Changing inputs

You can modify the inputs at runtime if you'd like to guide the fuzzer.  The array of inputs is directly accessible through `$r.inputs` (an array of buf8s) or through __`addinput(Blob)`__, __`addinput(Str)`__, or __`addinput(IO::Path)`__.

Radamsa will randomly choose one input for each ouput it generates, so choose your inputs wisely.

### Getting output
All results are `buf8` because there's no telling what you'll get.

__`gen1()`__

Returns a single item of output.
```
> for ^10 { say $r.gen1.decode }
fuzzfzzfuzzfuzz mefuzz me mefuzme
fuzz me mefuzz me
fuzz me mefuzz me mefuzz me
  mefuzz me
fuzz mefuzz me

fuz me
Malformed UTF-8 at line 1 col 1
  in block <unit> at <unknown file> line 1
```

### Getting a lot of ouput
The radamsa class is a Raku `Channel`, so you can call `.receive` on it. The queue will be empty until you initialize it with `.startchannel`. This starts a worker thread that tries to keep at least `$.minqsz` items available on the channel. Radamsa will naively increase its minqsz whenever the queue gets too short. It's not PID control, but it works for most usecases. You can outrun libradamsa with very quick tests. If that happens, ignore it or use fewer threads; libradamsa isn't thread safe.

Here is an example that writes to some temp files.

```
use Radamsa;
my $r = radamsa.new("go fuzz your software", :maxoutsz(100), :minqsz(100));
$r.startchannel();
my $keepgoing = True;
my @workers;
for ^10 {                                           # starting 10 threads
    my $fh = ('/tmp/libradtest'~$_).IO.open(:w);
    @workers.push(
        start {
            while ?$keepgoing {
                my $b = $r.receive;
                $b.append(0x0a);                    # newline to make it somewhat readable
                $fh.write($b);
            }
            $fh.close;
        }
    );
}
sleep 5;
$keepgoing = False;
await @workers;
```
and some of it's output
```
> head -n 5 /tmp/libradtest*
==> /tmp/libradtest0 <==
go fuzó   z your software
go fuzzË‘ Êµyour software
â€ó  ƒ‡go óÊ¶  §fuzz your sr sofï¿¿twaâ §ró  še
go fuzz your softwó  ³are
go fuzz your softwarego fuzz your só  ›oftware

==> /tmp/libradtest1 <==
go fuzz your ÷dLsoftware
g„1•259ó  €o fó €»uzzó  Žó  «ó  ´ your só ó  „ žoâ ¥ftware
go fuzz yoâ€ó €²‡ur sofáš€twaró €¢ó € e
go fuzz y só  ›o fuzz your software
go fuzz your softward

==> /tmp/libradtest2 <==
go fuzó  »z your software
go fuzz softwarego fuzz yoï»¿ur software
ó  ­go fuzz your software
go fuzz your softwarego fuzz your softwarego fuzz your softwarego fuzz your softwaregoï¼  fuzz your
go fuzz xour softw`re

==> /tmp/libradtest3 <==
go fuzz your â€¬software
go fuzz your softwarego fuzz your só  ›oftwarer software
go fuzzó  … your software
go fu fuzz youzz your softwarego fuzz your só  ›oftwarego fuzz your só  ›oftware
go ftware

==> /tmp/libradtest4 <==
à¿­go fuó  «zz yougo fuzz fuô 	¿¾zz your sÂ·ó  ›oftware
go fuzz your software
go fuzz yoó  ”ur software
go fuzz your sofó €¼tware
go fuzz your softwarego fuz

==> /tmp/libradtest5 <==
go fuzz your softwarego fuzz your softwarego fuzz your softwarego fuzz your softwarego fuzz your sof
go fuzz â€Šyour só  ¿oftwaróÂ·  ˜e
go fuzz your sofÂ tware
âó  »€ó  •á Žóó  ” €½„óï¬¬ ó ó  ’ Ÿgo fuzz yo fuzz your só  ›oftwarer software
go ftó  ›ware

==> /tmp/libradtest6 <==
go fuzó  ó  ©•z your software
go fuzz yoó €¹ur software
go fuzz your softwarego fuzz your só  ›oftware
goó  ur software
go your softwaretó  šsoftó  ‘ó  šsoftó  šsoftó  šsoftó  šsoftware

==> /tmp/libradtest7 <==
go fuz z your so fuzz your software
go Ê°fþÿuzz your soâ€®ftâ §warego fuó  ³zz yó €¯our só  ›ó  ‰oftware
go fuzz your software
go fuzz your software
ó  šsoftó  ftware

==> /tmp/libradtest8 <==
go fuzz yoâ€ˆur ó  ™software
go fuzz your softwarego fuzz your software
go fó €¤uzz yó  †our software
go fuzz your softwarez yoï»¿ur software
go fuzz your softó  ›ware

==> /tmp/libradtest9 <==
go fuzz you
go fuzz your softwarego fuzzgo fuzz your softwarego fuzz your só  ›oftware
go fuzz yoï»¿ur softwaregoe
go fuzz your softwarego fuzz your só  ›oftware
go fuï· zz your ó  šsofuzz ougo â€ªfuzz your softwarego fuzz your softwarego fuzz your só ó €± ›oftw
```
