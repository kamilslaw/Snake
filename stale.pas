unit stale;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  SDL,
  SDL_TTF;

{ deklaracje }
procedure Wytnij(var kw: pSDL_RECT; i: integer);
procedure Wytnij2(var kw: pSDL_RECT; i, modulo: integer);
procedure InicjujJezyk(s: string);
procedure ZaladujInfooMapie(trybGry: integer);
procedure LadowanieUstawien();

{ zmienne }
const
  ilWierszyPlikLang: integer = 19; { --!-- ilosc zdan! }
  KAMPANIA: integer = 6;
  TRYBWOLNY: integer = 7;
  RAMKA: integer = 130;         { FPS = 1000 / RAMKA }
  CZERWONY: integer = 10;
  ZIELONY: integer = 11;
  NIEBIESKI: integer = 12;
  FIOLETOWY: integer = 13;

var
  { aplikacja }
  ekran, sprite, napis: pSDL_SURFACE;
  kolor1, kolor2: pSDL_COLOR;
  czcionkad, czcionkam: pTTF_FONT;
  kw, poz: pSDL_RECT;
  zdarzenie: pSDL_EVENT;
  { podstawowe parametry gry }
  tekst: array[1..19] of string;   { --!-- ilosc zdan! }
  USTAWIENIAVIDEO: integer = SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_ASYNCBLIT;
  { testowac Z oraz BEZ SDL_ASYNCBLIT }
  ilRund, interwalDropu, nrOdblokMapy, popAktualnaMapa, ilMapTrybWolny: integer;
  aktualnaMapa: integer = 1;
  nazwaMapy, opisMapy, parametryMapy: string;
  szybkoscGry: integer = 3; { 1x-3x }
  tabelaGraczy: array[10..13] of integer = (1, 0, 0, 2);  { gracz - 1, AI - 2, brak - 0 }
  { stany gry }

  { nazwy sprite-ów }
  calosc: integer = 0;
  strzL1: integer = 1;
  strzL2: integer = 2;
  strzP1: integer = 3;
  strzP2: integer = 4;
  podgladMapy: integer = 5;
  podgladMapyRamka: integer = 6;
  caloscRamka: integer = 7;
  rozpocznijGre: integer = 8;
  tloPlansza: integer = 9;
  { nr sprite-ow zgadzaja sie z numerami elementow w plikach .map }
  blokZew: integer = 29;
  blok: integer = 30;
  teleport: integer = 31;
  speed: integer = 32;
  slow: integer = 33;
  zmianaKierunku: integer = 34;
  jedzenie: integer = 35;
  jedzenie3: integer = 36;
  generujSciane: integer = 37;
  generujPierscien: integer = 38;
  spirit: integer = 39;
  bialePole: integer = 40;
  pytajnik: integer = 666;

implementation

{ definicje }
procedure Wytnij(var kw: pSDL_RECT; i: integer);
var
  x, y, w, h: integer;
begin
  if i = caloscRamka then
  begin
    x := 0;
    y := 0;
    w := 900;
    h := 640;
  end
  else if i = calosc then
  begin
    x := 1;
    y := 1;
    w := 898;
    h := 638;
  end
  else if i = strzL1 then
  begin
    x := 600;
    y := 420;
    w := 12;
    h := 24;
  end
  else if i = strzL2 then
  begin
    x := 600;
    y := 372;
    w := 12;
    h := 48;
  end
  else if i = strzP1 then
  begin
    x := 600;
    y := 492;
    w := 12;
    h := 24;
  end
  else if i = strzP2 then
  begin
    x := 600;
    y := 444;
    w := 12;
    h := 48;
  end
  else if i = podgladMapy then
  begin
    x := 134;
    y := 360;
    w := 200;
    h := 200;
  end
  else if i = podgladMapyRamka then
  begin
    x := 133;
    y := 359;
    w := 202;
    h := 202;
  end
  else if i = rozpocznijGre then
  begin
    x := 610;
    y := 510;
    w := 190;
    h := 50;
  end
  else if i = tloPlansza then
  begin
    x := 0;
    y := 0;
    w := 600;
    h := 600;
  end;

  new(kw);
  kw^.x := x;
  kw^.y := y;
  kw^.w := w;
  kw^.h := h;
end;

procedure Wytnij2(var kw: pSDL_RECT; i, modulo: integer);
{ modulo - 1 niep 2 parz 0 brak }
var
  x, y, w, h, j: integer;
begin
  w := 12;
  h := 12;
  x := 600;

  if (i >= CZERWONY) and (i <= FIOLETOWY) then
    for j := CZERWONY to FIOLETOWY do
    begin
      if (j = i) and (modulo = 2) then
        y := 24 * (j - 10)
      else if (j = i) and (modulo = 1) then
        y := (24 * (j - 10)) + 12;
    end;
  if i = blokZew then
  begin
    if modulo = 2 then
    begin
      x := 588;
      y := 12;
    end
    else
    begin
      x := 588;
      y := 0;
    end;
  end
  else if i = blok then
  begin
    if modulo = 2 then
      y := 108
    else
      y := 120;
  end
  else if i = teleport then
  begin
    if modulo = 2 then
      y := 288
    else
      y := 300;
  end
  else if i = speed then
  begin
    if modulo = 2 then
      y := 240
    else
      y := 252;
  end
  else if i = slow then
  begin
    if modulo = 2 then
      y := 216
    else
      y := 228;
  end
  else if i = zmianaKierunku then
  begin
    if modulo = 2 then
      y := 264
    else
      y := 276;
  end
  else if i = jedzenie then
  begin
    if modulo = 2 then
      y := 168
    else
      y := 180;
  end
  else if i = jedzenie3 then
  begin
    if modulo = 2 then
      y := 192
    else
      y := 204;
  end
  else if i = generujSciane then
    y := 312
  else if i = generujPierscien then
    y := 324
  else if i = spirit then
    y := 348
  else if i = bialePole then
    y := 144
  else if i = pytajnik then
    y := 336;

  new(kw);
  kw^.x := x;
  kw^.y := y;
  kw^.w := w;
  kw^.h := h;
end;

procedure ZaladujInfooMapie(trybGry: integer);
var
  P: Text;
  s1: string;
begin
  if trybGry = KAMPANIA then
  begin
    Assign(P, 'map/campaign/' + IntToStr(aktualnaMapa) + '.txt');
    Reset(P);
    ReadLn(P, s1);
    ReadLn(P, nazwaMapy);
    ReadLn(P, opisMapy);
    ReadLn(P, parametryMapy);
    Close(P);
    popAktualnaMapa := aktualnaMapa;
  end
  else
  begin
    Assign(P, 'map/' + IntToStr(aktualnaMapa) + '.map');
    Reset(P);
    ReadLn(P, s1);
    ReadLn(P, nazwaMapy);
    ReadLn(P, opisMapy);
    Close(P);
    popAktualnaMapa := aktualnaMapa;
  end;
end;

procedure InicjujJezyk(s: string);
var
  P: Text;
  i: integer;
begin
  Assign(P, 'conf/lang/' + s);
  Reset(P);
  for i := 1 to ilWierszyPlikLang do
    ReadLn(P, tekst[i]);
  Close(P);
end;

procedure LadowanieUstawien();
var
  P: Text;
  s1, s2: string;
  i, j, k: integer;
begin
  Assign(P, 'conf/conf.txt');
  Reset(P);
  ReadLn(P, s1);
  ReadLn(P, s1);
  s2 := Copy(s1, Pos(':', s1) + 1, Pos(':', s1));
  InicjujJezyk(s2);
  ReadLn(P, s1);
  s2 := Copy(s1, Pos(':', s1) + 1, Pos(':', s1));
  if s2 = '1' then
    USTAWIENIAVIDEO := USTAWIENIAVIDEO or SDL_FULLSCREEN;
  ReadLn(P, s1);
  s2 := Copy(s1, Pos(':', s1) + 1, Pos(':', s1));
  ilRund := StrToInt(s2);
  ReadLn(P, s1);
  s2 := Copy(s1, Pos(':', s1) + 1, Pos(':', s1));
  interwalDropu := StrToInt(s2);
  Close(P);
  Assign(P, 'conf/save.dat');
  Reset(P);
  ReadLn(P, s2);
  ReadLn(P, s2);
  Close(P);
  { ladowanie informacji o mapach kampanii }
  Assign(P, 'conf/maps.dat');
  Reset(P);
  ReadLn(P, s1);
  ReadLn(P, s1);
  j := StrToInt(s1);
  for i := 1 to j do
  begin
    ReadLn(P, s1);
    if s1 = s2 then
      nrOdblokMapy := i;
  end;
  Close(P);
  aktualnaMapa := nrOdblokMapy;
  ZaladujInfooMapie(KAMPANIA);
  { ladowanie informacji o mapach trybu wolnego }
  ilMapTrybWolny := 0;
  k := 0;
  i := 1;
  while k = 0 do
  begin
    Assign(P, 'map/' + IntToStr(i) + '.map');
  {$I-}
    Reset(P);
  {$I+}
    if IOresult <> 0 then
    begin
      ilMapTrybWolny := i;
      k := 1;
    end;
    i := i + 1;
  end;
  ilMapTrybWolny := ilMapTrybWolny - 1;
end;

end.
