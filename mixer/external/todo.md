checknut test casy (musia fungovat!) //este recording -- ten som vobec nekukol

device precedence (vyber najlepsieho zvukoveho zariadnia na zaklade nejakych logickych kriterii - napr. pocet kanalov) -- asi nie je nutne kedze nulte zariadenie je default vo windowse

checknut preco crashuje recording (ako keby pri REALNOM nahravani zvuku to robilo problemy - ak sa nic neregistruje - nic sa nezapisuje - nie je crash.... - takisto mozno Sleep ???)

callback ? (ak sa nejako da checknut zmena aktivneho audio device vo Windowse)

co by bolo dobre je sa rozhodnut ze ako najlepsie zaznamenavat VELKE nahravky (
        pocet mensich Chunkov ?
        alebo mat nejaky "ReferenceWindow" ktory sa postupne bude menit ako sa nahravka bude predlzovat ?
        dalsia moznost je to urobit ako Stack alloc (cize tieto chunky budu mat fixnu velkost a bude predom dana napriklad 1024B na jeden SoundChunk))

dokoncit funkcie ktore nie su implementovane