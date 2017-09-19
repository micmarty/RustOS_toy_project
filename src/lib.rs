#![feature(lang_items)]
#![no_std]
extern crate rlibc;
extern crate cpuio;
//extern crate scancode;

use cpuio::Port;
//use scancode::Scancode;

//przelatuje po calym bloku pamieci od trybu tekstowego nadpisujac spacją z niebieskim tłem
unsafe fn czysc_ekran(pelny_znak: u16) {
    let mut poz = 0;
    while poz < 4000
    {
        let bufor = (0xb8000 + poz ) as *mut _;
        unsafe{*bufor = pelny_znak   };
        poz+=2;
    }
}

//wykrywa sekwence klawiszy 'cw'
unsafe fn shell_obsluz_komende_clear(scancode: u8,pelny_znak: u16, wskaznik: &mut u8,zatrzymaj_petle: &mut bool){
    // talbica z wyrazem clear w scancodach
    let mut tablica_sekwencji: [u8;3] = [0x2e,0x11,0];
    if scancode == tablica_sekwencji[*wskaznik as usize]{
        *wskaznik += (1 as u8); // przesun wskaznik na kolejny element
    }
    else{
        // jesli pomylono znak, to zaczynamy od nowa
        // *wskaznik = 0;
    }

    //wykryto 'cw'
    if(*wskaznik == 2){
            if(*zatrzymaj_petle == false){
                *zatrzymaj_petle = true;
            }
            else{
                *zatrzymaj_petle = false;
            }
            unsafe{czysc_ekran(pelny_znak)};
            *wskaznik = 0;
    }

}

#[no_mangle]
pub extern fn rust_main() {
    //JESLI WYSTAPI UNWINDING TO KERNEL BEDZIE SIE ZAPETLAŁ!
    //let x = ["Hello", "World", "!"];
    //let test = (0..3).flat_map(|x| 0..x).zip(0..);


// PROCEDURA -> wypelnij caly ekran na niebiesko
    let bajt_koloru: u16 = 0x1f;    //spacja z niebieskim tlem
    let bajt_znaku: u16 = 32;       //
    let pelny_znak: u16 = (bajt_koloru << 8) | bajt_znaku;
    unsafe{czysc_ekran(pelny_znak)};


// PROCEDURA -> wyswietl tekst poruszajacy sie po ekranie
    let text = b"Potrafie wyswietlac ->";

    let mut kolorowy_tekst = [bajt_koloru as u8; 44];
    for(i, char_byte) in text.into_iter().enumerate(){
        kolorowy_tekst[i*2] = *char_byte;
    }


    //od klawiatury i shella
    let mut keyboard: Port<u8> = unsafe { Port::new(0x60) };
    let pozycja_dla_scancodu = (0xb8000) as *mut _;
    let pozycja_dla_licznika = (0xb8002) as *mut _;
    let mut wskaznik_shella: u8 = 0;



    //animuj
    let mut offset = 0;
    let mut zakoncz = false;
    let mut licznik_opoznienia = 0;

    while !zakoncz
    {
        //nadpisujemy pustym znakiem
        let poprzedni = (0xb8000 + offset) as *mut _;
        unsafe{*poprzedni = pelny_znak };

        offset+=2;

        //wpisujemy wlasciwy znak
        let buffer_ptr = (0xb8000 + offset) as *mut _;
        unsafe{*buffer_ptr = kolorowy_tekst };


        let mut scancode: u8 = keyboard.read();
        unsafe{
            // przechwytuj wymagane klawisze
            shell_obsluz_komende_clear(scancode,pelny_znak,&mut wskaznik_shella,&mut zakoncz);

            // wyswietla ile klawiszy wcisnieto
            let tmp: u8 = wskaznik_shella + 0x30;//konwersja na ascii
            let mut ascii: u16 = (bajt_koloru << 8) | tmp as u16;
            *pozycja_dla_licznika = ascii;

            //skankod klawisza jako ascii(niepoprawna interpretacja)
            ascii = (bajt_koloru << 8) | scancode as u16;
            *pozycja_dla_scancodu = ascii;
        };

        //koniec bufora ekranu
        if offset == (4000-44)
        {
            //zakoncz = true;
            //przenies na poczatek
            offset = 0;
        }
        while licznik_opoznienia < 100000
        {
            licznik_opoznienia+=1;
        }
        licznik_opoznienia = 0;
    }

    // po sekwencji przerywajacej, dalej wyswietlaj licznik i skankod
    loop
    {
        let mut scancode: u8 = keyboard.read();
        unsafe{
            // przechwytuj wymagane klawisze
            shell_obsluz_komende_clear(scancode,pelny_znak,&mut wskaznik_shella,&mut zakoncz);

            // wyswietla ile klawiszy wcisnieto
            let tmp: u8 = wskaznik_shella + 0x30;//konwersja na ascii
            let mut ascii: u16 = (bajt_koloru << 8) | tmp as u16;
            *pozycja_dla_licznika = ascii;

            //skankod klawisza jako ascii(niepoprawna interpretacja)
            ascii = (bajt_koloru << 8) | scancode as u16;
            *pozycja_dla_scancodu = ascii;
        };
    }

}

//chwilowo wylaczam dla crate scancodow
//reszta w dokumentacji
#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] extern fn panic_fmt() -> ! {loop{}}


//sztuczna funkcja jesli cargo.toml nas nie zabezpieczy przed unwindem
#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! {
    loop {}
}
