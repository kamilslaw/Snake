unit gra;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  CRT,
  SDL,
  SDL_TTF,
  stale,
  lista;

{ deklaracje }
procedure ROZPOCZNIJ_GRE(tGry, nrM: integer; parGry: string);
procedure DRAW();
procedure UPDATE();
procedure SYMULUJ();
procedure ResetujGre(tGry, nrM: integer; parGry: string);
procedure ResetujPlansze();
procedure RysujHUD(kolorGracza, x, y: integer);
procedure RysujHUDstart(kolorGracza, x, y: integer);
procedure KierunkiRuchu();
procedure ZmniejszEfekty();
procedure ObliczPozycje();
procedure SprawdzKolizje();
procedure GenerujDrop();
procedure WstawObiektyIPrzytnij();
procedure WykonajRuch();
procedure SprawdzPole();
procedure UstawDrop();

{ zmienne }
const
  PAUZA: integer = 0;
  START: integer = 1;
  GRAJ: integer = 2;
  KONIECGRY: integer = 3;
  KONIECRUNDY: integer = 4;
  WYGRANA: integer = 5;
  SKUTY: integer = -1;
  GORA: integer = 20;
  PRAWO: integer = 21;
  DOL: integer = 22;
  LEWO: integer = 23;
  GRACZ: integer = 1;
  AI: integer = 2;

var
  petlaGry: boolean;
  stanGry, SEKUNDNIK, DROP, RING: integer;
  kierunekGracza: array[10..13] of integer;   { wykonaj ruch jezeli inny niz -1 (skuty) }
  klawiszGracza: array[10..13] of integer;
  tabelaGraczy1: array[10..13] of integer;    { 0/1/2 - pusty slot/gracz/AI }
  wynikGracza: array[10..13] of integer;
  moceGracza: array[10..13] of array[1..4] of integer;
  { przyspieszenie, spowolnienie, przechodzenie przez sciany, zamiana klawiszy - wartosc (17) * (4) * szybkoscGry }
  czasDoRuchu: array[10..13] of integer;
  { ilosc ramek (FPS) do wykonania przesuniecia (zmiana szybkosci) }
  nastepnaPozycja: array[10..13] of integer; { nr nastepnej pozycji glowy }
  kolejkaSegmenty: array[10..13] of integer; { ilosc segmentow czekajacych na wrzucenie }
  ruchGracza: array[10..13] of array[1..2] of integer;
  { [liczba przebiegow do ruchu, aktualna liczba przebiegow] }
  weze: array[10..13] of wazWsk;
  parametryGry: string;
  warunekWygranej: string;
  { NIESKONCZONOSC, ILRUND / DLUGOSC:war, CZAS:war, ZAPELNIENIE:war }
  zabudowywanie, bezBonusow: boolean;
  trybGry, nrMapy, i, j, k, iloscRund: integer;
  PLANSZA: array[1..2500] of array[1..2] of integer; { [rodzaj bloku, wlasciwosc] }
  tabelaDropu: array[1..30] of integer;  { okresla prawdopodobienstwo wylosowania dropu }
  oczekujaceBloki, oczekujacePierscienie: integer; { liczba czekajacych na wstawienie }
  celGracza: array[10..13] of integer; { pole do ktorego ma dazyc (dla SI) }
  trybSymulacji: boolean = False; { do sledzenia zachowan SI }

implementation

procedure ROZPOCZNIJ_GRE(tGry, nrM: integer; parGry: string);
var
  P: Text;
  s1, s2: string;
  i, j, k: integer;
begin
  ResetujGre(tGry, nrM, parGry);
  { GLOWNA petla gry }
  while petlaGry = False do
  begin
    if SDL_POLLEVENT(zdarzenie) = 1 then
    begin
      case zdarzenie^.type_ of
        SDL_KEYDOWN:
        begin
          if zdarzenie^.key.keysym.sym = SDLK_ESCAPE then
            petlaGry := True
          else
          begin
            if (zdarzenie^.key.keysym.sym = SDLK_p) and (stanGry = GRAJ) then
              stanGry := PAUZA
            else if (zdarzenie^.key.keysym.sym = SDLK_p) and (stanGry = PAUZA) then
              stanGry := GRAJ;
            if (zdarzenie^.key.keysym.sym = SDLK_SPACE) and (stanGry = START) then
              stanGry := GRAJ;
            if zdarzenie^.key.keysym.sym = SDLK_F1 then
            begin
              if trybSymulacji = True then
                trybSymulacji := False
              else
                trybSymulacji := True;
            end;
            if (tabelaGraczy1[CZERWONY] = GRACZ) and (stanGry = GRAJ) then
            begin
              if zdarzenie^.key.keysym.sym = SDLK_LEFT then
                klawiszGracza[CZERWONY] := LEWO;
              if zdarzenie^.key.keysym.sym = SDLK_RIGHT then
                klawiszGracza[CZERWONY] := PRAWO;
            end;
            if (tabelaGraczy1[ZIELONY] = GRACZ) and (stanGry = GRAJ) then
            begin
              if zdarzenie^.key.keysym.sym = SDLK_a then
                klawiszGracza[ZIELONY] := LEWO;
              if zdarzenie^.key.keysym.sym = SDLK_d then
                klawiszGracza[ZIELONY] := PRAWO;
            end;
            if (tabelaGraczy1[NIEBIESKI] = GRACZ) and (stanGry = GRAJ) then
            begin
              if zdarzenie^.key.keysym.sym = SDLK_v then
                klawiszGracza[NIEBIESKI] := LEWO;
              if zdarzenie^.key.keysym.sym = SDLK_n then
                klawiszGracza[NIEBIESKI] := PRAWO;
            end;
            if (tabelaGraczy1[FIOLETOWY] = GRACZ) and (stanGry = GRAJ) then
            begin
              if zdarzenie^.key.keysym.sym = SDLK_u then
                klawiszGracza[FIOLETOWY] := LEWO;
              if zdarzenie^.key.keysym.sym = SDLK_o then
                klawiszGracza[FIOLETOWY] := PRAWO;
            end;
          end;
        end;
      end;
    end;
    SYMULUJ();       { wykonanie ruch przez AI }
    UPDATE();
    SDL_DELAY(Round(RAMKA / (szybkoscGry * 2)));
  end;
end;

procedure ResetujGre(tGry, nrM: integer; parGry: string);
var
  P: Text;
  s1, s2: string;
  i, j, k: integer;
begin
  { konfigurowanie rozgrywki }
  petlaGry := False;
  parametryGry := parGry;
  trybGry := tGry;
  nrMapy := nrM;
  DROP := Round(interwalDropu * (1000 / (RAMKA))); {/ (szybkoscGry * 2))));  }
  RING := 7 * DROP;
  UstawDrop();
  for i := CZERWONY to FIOLETOWY do
    wynikGracza[i] := 0;
  ResetujPlansze();
  { ustalenie warunku na zwyciestwo }
  if trybGry = TRYBWOLNY then
  begin
    { sprawdzenie czy na planszy jest jeden gracz }
    k := 0;
    if Pos('CZERWONY', parametryGry) <> 0 then
      k := k + 1;
    if Pos('ZIELONY', parametryGry) <> 0 then
      k := k + 1;
    if Pos('NIEBIESKI', parametryGry) <> 0 then
      k := k + 1;
    if Pos('FIOLETOWY', parametryGry) <> 0 then
      k := k + 1;
    if k = 1 then
      warunekWygranej := 'NIESKONCZONOSC'
    else
    begin
      warunekWygranej := 'ILRUND';
      iloscRund := ilRund;
    end;
  end
  else
  begin
    s1 := '';
    if Pos('DLUGOSC', parametryGry) <> 0 then
    begin
      k := Pos('DLUGOSC:', parametryGry) + 8;
      while Pos('#', s1) = 0 do
      begin
        s2 := parametryGry[k];
        s1 := s1 + s2;
        k := k + 1;
      end;
      warunekWygranej := 'DLUGOSC:' + Copy(s1, 1, Length(s1) - 1);
    end
    else if Pos('CZAS', parametryGry) <> 0 then
    begin
      k := Pos('CZAS:', parametryGry) + 5;
      while Pos('#', s1) = 0 do
      begin
        s2 := parametryGry[k];
        s1 := s1 + s2;
        k := k + 1;
      end;
      warunekWygranej := 'CZAS:' + Copy(s1, 1, length(s1) - 1);
    end
    else if Pos('ZAPELNIENIE', parametryGry) <> 0 then
    begin
      k := Pos('ZAPELNIENIE:', parametryGry) + 12;
      while Pos('#', s1) = 0 do
      begin
        s2 := parametryGry[k];
        s1 := s1 + s2;
        k := k + 1;
      end;
      warunekWygranej := 'ZAPELNIENIE:' + Copy(s1, 1, Length(s1) - 1);
    end;
  end;
  { dodatkowe cechy gry (kampania }
  zabudowywanie := False;
  bezBonusow := False;
  if Pos('PETLA', parametryGry) <> 0 then
    zabudowywanie := True;
  if Pos('BB', parametryGry) <> 0 then
    bezBonusow := True;
end;

procedure ResetujPlansze();
var
  P: Text;
  s1: string;
  i, j, k: integer;
begin
  SEKUNDNIK := 0;
  for i := CZERWONY to FIOLETOWY do
  begin
    stanGry := START;
    New(weze[i]);
    weze[i]^.wsk := nil;
    klawiszGracza[i] := 0;
    tabelaGraczy1[i] := 0;
    kierunekGracza[i] := -1;
    nastepnaPozycja[i] := -1;
    kolejkaSegmenty[i] := 8;   { tak aby waz po wystartowaniu osiagnal dlugosc 10 }
    if ((nrMapy = 11) and (trybGry = TRYBWOLNY)) or
      ((nrMapy = 5) and (trybGry = KAMPANIA)) then
      kolejkaSegmenty[i] := 23;     { do wywalenia - 'bonus' w etapie 11 }
    oczekujaceBloki := 0;
    oczekujacePierscienie := 0;
    ruchGracza[i, 1] := 2;
    ruchGracza[i, 2] := 0;
    celGracza[i] := 0;
    for j := 1 to 4 do
      moceGracza[i, j] := 0;
  end;
  if Pos('CZERWONY:1', parametryGry) <> 0 then
    tabelaGraczy1[CZERWONY] := GRACZ
  else if Pos('CZERWONY:2', parametryGry) <> 0 then
    tabelaGraczy1[CZERWONY] := AI;
  if Pos('ZIELONY:1', parametryGry) <> 0 then
    tabelaGraczy1[ZIELONY] := GRACZ
  else if Pos('ZIELONY:2', parametryGry) <> 0 then
    tabelaGraczy1[ZIELONY] := AI;
  if Pos('NIEBIESKI:1', parametryGry) <> 0 then
    tabelaGraczy1[NIEBIESKI] := GRACZ
  else if Pos('NIEBIESKI:2', parametryGry) <> 0 then
    tabelaGraczy1[NIEBIESKI] := AI;
  if Pos('FIOLETOWY:1', parametryGry) <> 0 then
    tabelaGraczy1[FIOLETOWY] := GRACZ
  else if Pos('FIOLETOWY:2', parametryGry) <> 0 then
    tabelaGraczy1[FIOLETOWY] := AI;
  if trybGry = KAMPANIA then
    tabelaGraczy1[CZERWONY] := GRACZ;
  szybkoscGry := 1;
  if Pos('SZYBKOSC:2', parametryGry) <> 0 then
    szybkoscGry := 2
  else if Pos('SZYBKOSC:3', parametryGry) <> 0 then
    szybkoscGry := 3;
  { tworzenie planszy i ustalenie kierunku jazdy }
  for i := 1 to 2500 do
    for j := 1 to 2 do
      PLANSZA[i, j] := -1;
  if trybGry = KAMPANIA then
  begin
    Assign(P, 'map/campaign/' + IntToStr(nrMapy) + '.map');
    Reset(P);
    ReadLn(P, s1);
  end
  else
  begin
    Assign(P, 'map/' + IntToStr(nrMapy) + '.map');
    Reset(P);
    ReadLn(P, s1);
    ReadLn(P, s1);
    ReadLn(P, s1);
  end;
  while not EOF(P) do
  begin
    ReadLn(P, s1);
    i := StrToInt(Copy(s1, 1, Pos(':', s1) - 1)); { pozycja }
    j := -1;
    j := StrToInt(Copy(s1, Pos(':', s1) + 1, 2)); { wartosc }
    k := -1;
    k := StrToInt(Copy(s1, Pos(';', s1) + 1, 2)); { wlasciwosc }
    if ((j = CZERWONY) and (tabelaGraczy1[CZERWONY] > 0)) then
      PLANSZA[i, 1] := CZERWONY
    else if ((j = ZIELONY) and (tabelaGraczy1[ZIELONY] > 0)) then
      PLANSZA[i, 1] := ZIELONY
    else if ((j = NIEBIESKI) and (tabelaGraczy1[NIEBIESKI] > 0)) then
      PLANSZA[i, 1] := NIEBIESKI
    else if ((j = FIOLETOWY) and (tabelaGraczy1[FIOLETOWY] > 0)) then
      PLANSZA[i, 1] := FIOLETOWY
    else if ((j < CZERWONY) or (j > FIOLETOWY)) then
      PLANSZA[i, 1] := j;
    if (Pos(';', s1) <> 0) and (PLANSZA[i, 1] > 0) then
      PLANSZA[i, 2] := k;
    for k := CZERWONY to FIOLETOWY do
      if (PLANSZA[i, 1] = k) and (PLANSZA[i, 2] > 0) then
      begin
        kierunekGracza[k] := PLANSZA[i, 2];
        weze[k]^.nr := i;
      end;
  end;
  Close(P);
  for i := 1 to 2500 do
  begin
    if (i < 51) or (i > 2450) then
      PLANSZA[i, 1] := 29
    else if ((i mod 50) = 0) or ((i mod 50) = 1) then
      PLANSZA[i, 1] := 29
    else
    begin
      { dodawanie elementow do listy weze }
      for k := CZERWONY to FIOLETOWY do
        if (PLANSZA[i, 1] = k) and (PLANSZA[i, 2] = 0) then
          DodajElement(weze[k], i);
    end;
  end;
  { rysowanie planszy }
  Wytnij(kw, caloscRamka);
  SDL_FillRect(ekran, kw, $333333);
  Wytnij(kw, calosc);
  SDL_FillRect(ekran, kw, $000000); { tymczasowe - do usuniecia }
  if tabelaGraczy1[CZERWONY] > 0 then
    RysujHUDstart(CZERWONY, 22, 52);
  if tabelaGraczy1[ZIELONY] > 0 then
    RysujHUDstart(ZIELONY, 22, 312);
  if tabelaGraczy1[NIEBIESKI] > 0 then
    RysujHUDstart(NIEBIESKI, 822, 52);
  if tabelaGraczy1[FIOLETOWY] > 0 then
    RysujHUDstart(FIOLETOWY, 822, 312);
end;

procedure UstawDrop();
var
  i: integer;
begin
  for i := 1 to 11 do
    tabelaDropu[i] := jedzenie;
  for i := 12 to 16 do
    tabelaDropu[i] := jedzenie3;
  tabelaDropu[17] := speed;
  tabelaDropu[18] := speed;
  tabelaDropu[19] := slow;
  tabelaDropu[20] := slow;
  tabelaDropu[21] := zmianaKierunku;
  tabelaDropu[22] := zmianaKierunku;
  tabelaDropu[23] := generujSciane;
  tabelaDropu[24] := generujSciane;
  tabelaDropu[25] := spirit;
  tabelaDropu[26] := spirit;
  tabelaDropu[27] := generujPierscien;
  for i := 28 to 30 do
    tabelaDropu[i] := jedzenie;
end;

procedure DRAW();
var
  i, modulo, x, y, k: integer;
begin
  { rysowanie planszy }
  Wytnij(kw, tloplansza);
  poz^.x := 150;
  poz^.y := 20;
  poz^.w := kw^.w;
  poz^.h := kw^.h;
  SDL_BLITSURFACE(sprite, kw, ekran, poz);
  SDL_FLIP(ekran);
  { rysowanie elementow }
  poz^.w := 12;
  poz^.h := 12;
  for i := 1 to 2500 do
  begin
    if (i < 51) or (i > 2450) or ((i mod 50) = 0) or ((i mod 50) = 1) then
    begin
      if PLANSZA[i, 1] = 40 then
      begin
        Wytnij2(kw, 40, 0);
        poz^.x := (x * 12) + 150;
        poz^.y := (y * 12) + 20;
        SDL_BLITSURFACE(sprite, kw, ekran, poz);
      end;
    end
    else
    begin
      if PLANSZA[i, 1] <> -1 then
      begin
        x := ((i - 1) mod 50);
        y := (Trunc(i / 50));
        if ((x + y) mod 2) = 1 then
          modulo := 1
        else
          modulo := 2;
        if (PLANSZA[i, 2] = 2) and (PLANSZA[i, 1] <> 31) then
          Wytnij2(kw, pytajnik, modulo)
        else
          Wytnij2(kw, PLANSZA[i, 1], modulo);
        poz^.x := (x * 12) + 150;
        poz^.y := (y * 12) + 20;
        SDL_BLITSURFACE(sprite, kw, ekran, poz);
      end;
    end;
  end;
  { rysowanie bialych Pol }
  for i := CZERWONY to FIOLETOWY do
  begin
    if (kierunekGracza[i] = SKUTY) and (tabelaGraczy1[i] > 0) then
    begin
      x := ((weze[i]^.nr) - 1) mod 50;
      y := (Trunc((weze[i]^.nr) / 50));
      Wytnij2(kw, bialePole, modulo);
      poz^.x := (x * 12) + 150;
      poz^.y := (y * 12) + 20;
      SDL_BLITSURFACE(sprite, kw, ekran, poz);
    end;
  end;
  { rysowanie HUD }
  if tabelaGraczy1[CZERWONY] > 0 then
    RysujHUD(CZERWONY, 22, 52);
  if tabelaGraczy1[ZIELONY] > 0 then
    RysujHUD(ZIELONY, 22, 312);
  if tabelaGraczy1[NIEBIESKI] > 0 then
    RysujHUD(NIEBIESKI, 822, 52);
  if tabelaGraczy1[FIOLETOWY] > 0 then
    RysujHUD(FIOLETOWY, 822, 312);
  { oczekiwanie na nacisniecie spacji }
  if stanGry = START then
  begin
    poz^.x := 247;
    poz^.y := 220;
    kolor1^.r := 255;
    kolor1^.g := 255;
    kolor1^.b := 255;
    kolor2^.r := 0;
    kolor2^.g := 0;
    kolor2^.b := 0;
    napis := TTF_RenderText_Shaded(czcionkad, PChar(tekst[12]), kolor1^, kolor2^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
  end
  { oczekiwanie na nacisniecie p (pauza) }
  else if stanGry = PAUZA then
  begin
    poz^.x := 259;
    poz^.y := 220;
    kolor1^.r := 255;
    kolor1^.g := 255;
    kolor1^.b := 255;
    kolor2^.r := 0;
    kolor2^.g := 0;
    kolor2^.b := 0;
    napis := TTF_RenderText_Shaded(czcionkad, PChar(tekst[13]), kolor1^, kolor2^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
  end;
  { koniec gry }
  if (stanGry = KONIECGRY) or (stanGry = WYGRANA) then
  begin
    if tabelaGraczy1[CZERWONY] > 0 then
      RysujHUDstart(CZERWONY, 22, 52);
    if tabelaGraczy1[ZIELONY] > 0 then
      RysujHUDstart(ZIELONY, 22, 312);
    if tabelaGraczy1[NIEBIESKI] > 0 then
      RysujHUDstart(NIEBIESKI, 822, 52);
    if tabelaGraczy1[FIOLETOWY] > 0 then
      RysujHUDstart(FIOLETOWY, 822, 312);
    k := 0;
    for i := CZERWONY to FIOLETOWY do
      if wynikGracza[i] >= iloscRund then
        k := i;
    poz^.x := 259;
    poz^.y := 220;
    kolor1^.r := 255;
    kolor1^.g := 255;
    kolor1^.b := 255;
    kolor2^.r := 0;
    kolor2^.g := 0;
    kolor2^.b := 0;
    napis := TTF_RenderText_Shaded(czcionkad, PChar(tekst[19]), kolor1^, kolor2^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
  end;

  SDL_FLIP(ekran);
end;

procedure RysujHUD(kolorGracza, x, y: integer);
begin
  poz^.x := x + 20;
  poz^.h := 80;
  poz^.y := y + 22;
  poz^.w := 40;
  SDL_FillRect(ekran, poz, $000000);
  poz^.x := x + 20;
  poz^.h := 3;
  poz^.y := y + 22;
  poz^.w := Round(0.5 * moceGracza[kolorGracza, 1] / szybkoscGry);
  SDL_FillRect(ekran, poz, $00FF00);
  poz^.y := y + 27;
  poz^.w := Round(0.5 * moceGracza[kolorGracza, 2] / szybkoscGry);
  SDL_FillRect(ekran, poz, $FF0000);
  poz^.y := y + 32;
  poz^.w := Round(0.5 * moceGracza[kolorGracza, 3] / szybkoscGry);
  SDL_FillRect(ekran, poz, $00FFFF);
  poz^.y := y + 37;
  poz^.w := Round(0.5 * moceGracza[kolorGracza, 4] / szybkoscGry);
  SDL_FillRect(ekran, poz, $888888);
end;

procedure RysujHUDstart(kolorGracza, x, y: integer);
begin
  Wytnij2(kw, kolorGracza, 1);
  poz^.x := x;
  poz^.y := y;
  poz^.w := 12;
  poz^.h := 12;
  SDL_BLITSURFACE(sprite, kw, ekran, poz);
  poz^.x := x + 14;
  poz^.y := y;
  SDL_BLITSURFACE(sprite, kw, ekran, poz);
  poz^.x := x + 28;
  poz^.y := y;
  SDL_BLITSURFACE(sprite, kw, ekran, poz);
  Wytnij2(kw, kolorGracza, 2);
  poz^.x := x + 42;
  poz^.y := y;
  SDL_BLITSURFACE(sprite, kw, ekran, poz);
  if (wynikGracza[kolorGracza] >= iloscRund) and (iloscRund > 0) then
  begin
    kolor1^.r := 255;
    kolor1^.g := 128;
    kolor1^.b := 0;
  end
  else
  begin
    kolor1^.r := 255;
    kolor1^.g := 255;
    kolor1^.b := 255;
  end;
  kolor2^.r := 0;
  kolor2^.g := 0;
  kolor2^.b := 0;
  poz^.x := x;
  poz^.y := y + 18;
  poz^.w := 120;
  poz^.h := 120;
  napis := TTF_RenderText_Shaded(czcionkad, PChar(IntToStr(wynikGracza[kolorGracza])),
    kolor1^, kolor2^);
  SDL_BLITSURFACE(napis, nil, ekran, poz);
end;

procedure UPDATE();
begin
  if stanGry = GRAJ then
  begin
    SEKUNDNIK := SEKUNDNIK + 1;
    { ustawienie kierunku ruchu }
    KierunkiRuchu();
    { zmniejszenie efektow }
    ZmniejszEfekty();
    { generowanie bonusow / wstawienie bonusow / wrzucanie pierscieni (kampania) }
    GenerujDrop();
    { obliczenie nastepnej pozycji }
    ObliczPozycje();
    { wykonanie ruchu / wstawienie na plansze oczekujacych segmentow wezy / zebranie bonusow }
    WykonajRuch();
    { sprawdzenie czy nie zachodza na obiekty, w tym na siebie nawzajem / wstawienie glow na PLANSZE / usuniecie kierunku z 2 segmentow wezy }
    SprawdzKolizje();
    { jesli zajdzie, wykonaj wstawienie obiektow na plansze (sciany), ewentualnie utnij weze }
    WstawObiektyIPrzytnij();
    { sprawdzenie planszy (warunki wygranej) }
    SprawdzPole();
  end;
  { rysowanie }
  DRAW();
end;

procedure KierunkiRuchu();
begin
  for i := CZERWONY to FIOLETOWY do
  begin
    if kierunekGracza[i] <> SKUTY then
    begin
      { zmiana klawiszy - efekt }
      if moceGracza[i, 4] > 0 then
      begin
        if klawiszGracza[i] = LEWO then
          klawiszGracza[i] := PRAWO
        else if klawiszGracza[i] = PRAWO then
          klawiszGracza[i] := LEWO;
      end;
      { ustalanie kierunku poruszania }
      if kierunekGracza[i] = GORA then
      begin
        if klawiszGracza[i] = LEWO then
          kierunekGracza[i] := LEWO
        else if klawiszGracza[i] = PRAWO then
          kierunekGracza[i] := PRAWO;
      end
      else if kierunekGracza[i] = PRAWO then
      begin
        if klawiszGracza[i] = LEWO then
          kierunekGracza[i] := GORA
        else if klawiszGracza[i] = PRAWO then
          kierunekGracza[i] := DOL;
      end
      else if kierunekGracza[i] = DOL then
      begin
        if klawiszGracza[i] = LEWO then
          kierunekGracza[i] := PRAWO
        else if klawiszGracza[i] = PRAWO then
          kierunekGracza[i] := LEWO;
      end
      else if kierunekGracza[i] = LEWO then
      begin
        if klawiszGracza[i] = LEWO then
          kierunekGracza[i] := DOL
        else if klawiszGracza[i] = PRAWO then
          kierunekGracza[i] := GORA;
      end;
      klawiszGracza[i] := 0;
    end;
  end;
end;

procedure ZmniejszEfekty();
var
  i, j: integer;
begin
  for i := CZERWONY to FIOLETOWY do
  begin
    if kierunekGracza[i] > 0 then
    begin
      { przechodzenie przez sciany i zamiana klawiszy }
      if moceGracza[i, 3] > 0 then
        moceGracza[i, 3] := moceGracza[i, 3] - 1;
      if moceGracza[i, 4] > 0 then
        moceGracza[i, 4] := moceGracza[i, 4] - 1;
      { spowolnienie i przyspieszenie }
      if moceGracza[i, 1] > 0 then
        moceGracza[i, 1] := moceGracza[i, 1] - 1;
      if moceGracza[i, 2] > 0 then
        moceGracza[i, 2] := moceGracza[i, 2] - 1;
      if (moceGracza[i, 1] = 0) and (moceGracza[i, 2] = 0) then
        ruchGracza[i, 1] := 2
      else if (moceGracza[i, 1] > 0) and (moceGracza[i, 2] > 0) then
        ruchGracza[i, 1] := 2
      else if (moceGracza[i, 1] = 0) and (moceGracza[i, 2] > 0) then
        ruchGracza[i, 1] := 4
      else if (moceGracza[i, 1] > 0) and (moceGracza[i, 2] = 0) then
        ruchGracza[i, 1] := 1;
      { zerowanie minusow }
      for j := 1 to 4 do
        if moceGracza[i, j] < 0 then
          moceGracza[i, j] := 0;
    end;
  end;
end;

procedure GenerujDrop();
var
  i, j, k, bezpiecznik: integer;
begin
  if stanGry = GRAJ then
  begin
    if (SEKUNDNIK mod DROP = 0) and (bezBonusow = False) then
    begin
      randomize();
      i := random(7) + 1;
      if i mod 2 = 0 then
      begin
        k := 0;
        bezpiecznik := 0;
        while k = 0 do
        begin
          i := (random(2499) + 1);
          if PLANSZA[i, 1] = (-1) then
          begin
            PLANSZA[i, 1] := tabelaDropu[random(29) + 1];
            j := random(11) + 1;
            if j mod 4 = 0 then
              PLANSZA[i, 2] := 2
            else
              PLANSZA[i, 2] := 1;
            k := 1;
          end;
          bezpiecznik := bezpiecznik + 1;
          if bezpiecznik > 10 then
            k := 1;
        end;
      end;
    end
    else if (SEKUNDNIK mod DROP = 0) and (bezBonusow = True) then
    begin
      randomize();
      i := random(7) + 1;
      if i mod 2 = 0 then
      begin
        k := 0;
        bezpiecznik := 0;
        while k = 0 do
        begin
          i := (random(2499) + 1);
          if PLANSZA[i, 1] = (-1) then
          begin
            PLANSZA[i, 1] := jedzenie;
            PLANSZA[i, 2] := 1;
            k := 1;
          end;
          bezpiecznik := bezpiecznik + 1;
          if bezpiecznik > 10 then
            k := 1;
        end;
      end;
    end;
    if (SEKUNDNIK mod RING = 0) and (zabudowywanie = True) then
      oczekujacePierscienie := oczekujacePierscienie + 1;
  end;
end;

procedure ObliczPozycje();
var
  i, j, tymPoz, c, nTel: integer;
begin
  if stanGry = GRAJ then
  begin
    for i := CZERWONY to FIOLETOWY do
    begin
      if kierunekGracza[i] > 0 then
      begin
        nastepnaPozycja[i] := -1;
        if ruchGracza[i, 2] >= ruchGracza[i, 1] then
        begin
          ruchGracza[i, 2] := 0;
          tymPoz := weze[i]^.nr;
          { obliczenie dla pustej przestrzeni }
          if kierunekGracza[i] = GORA then
            tymPoz := weze[i]^.nr - 50
          else if kierunekGracza[i] = PRAWO then
            tymPoz := weze[i]^.nr + 1
          else if kierunekGracza[i] = DOL then
            tymPoz := weze[i]^.nr + 50
          else if kierunekGracza[i] = LEWO then
            tymPoz := weze[i]^.nr - 1;
          if (tymPoz > 0) and (tymPoz < 2501) then
          begin
            if (PLANSZA[tymPoz, 1] = (-1)) or (PLANSZA[tymPoz, 1] = 0) or
              (PLANSZA[tymPoz, 1] = 30) or ((PLANSZA[tymPoz, 1] > 31) and
              (PLANSZA[tymPoz, 1] < 40)) or
              ((PLANSZA[tymPoz, 1] >= CZERWONY) and
              (PLANSZA[tymPoz, 1] <= FIOLETOWY)) then
              nastepnaPozycja[i] := tymPoz;
          end;
          { obliczenie dla konca planszy }
          if (PLANSZA[tymPoz, 1] = blokZew) and (moceGracza[i, 3] <= 0) then
            nastepnaPozycja[i] := tymPoz
          else if (PLANSZA[tymPoz, 1] = blokZew) and (moceGracza[i, 3] > 0) then
          begin
            { sprawdzenie wolnej pozycji (ilosci pierscieni obwodu) }
            { c := 1;
            k := 0;
            while k = 0 do
            begin
              if PLANSZA[50 + c, 1] <> blokZew then
                k := 1
              else
                c := c + 1;
            end; }
            if (kierunekGracza[i] = PRAWO) or (kierunekGracza[i] = LEWO) then
              nastepnaPozycja[i] := weze[i]^.nr + 51 - ((weze[i]^.nr mod 50) * 2)
            else if (kierunekGracza[i] = GORA) or (kierunekGracza[i] = DOL) then
              nastepnaPozycja[i] :=
                ((50 - Trunc(weze[i]^.nr / 50)) * 50) - 50 + (weze[i]^.nr mod 50);
          end;
          { obliczenie dla teleportu }
          if (PLANSZA[tymPoz, 1] = teleport) then
          begin
            nTel := (-1);
            if PLANSZA[tymPoz, 2] mod 2 = 0 then
              c := PLANSZA[tymPoz, 2] - 1
            else
              c := PLANSZA[tymPoz, 2] + 1;
            for j := 1 to 2500 do
              if (PLANSZA[j, 1] = teleport) and (PLANSZA[j, 2] = c) then
                nTel := j;
            if nTel <> (-1) then
            begin
              if kierunekGracza[i] = GORA then
                tymPoz := nTel - 50
              else if kierunekGracza[i] = PRAWO then
                tymPoz := nTel + 1
              else if kierunekGracza[i] = DOL then
                tymPoz := nTel + 50
              else if kierunekGracza[i] = LEWO then
                tymPoz := nTel - 1;
              nastepnaPozycja[i] := tymPoz;
            end
            else
            begin
              nastepnaPozycja[i] := tymPoz;
              kierunekGracza[i] := SKUTY;
            end;
          end;
        end
        else
          ruchGracza[i, 2] := ruchGracza[i, 2] + 1;
      end;
    end;
  end;
end;

procedure WstawObiektyIPrzytnij();
var
  i, j, k, c, bezpiecznik: integer;
  tymWsk: wazWsk;
begin
  { wstawienie pojedynczyh blokow }
  if stanGry = GRAJ then
  begin
    if oczekujaceBloki > 0 then
    begin
      oczekujaceBloki := oczekujaceBloki - 1;
      randomize();
      k := 0;
      bezpiecznik := 0;
      while k = 0 do
      begin
        i := (random(2499) + 1);
        if (PLANSZA[i, 1] <= 0) then  {((PLANSZA[i, 1] >= CZERWONY) and }
          { (PLANSZA[i, 1] <= FIOLETOWY) and (PLANSZA[i, 2] <= 0)) then   }
        begin
          PLANSZA[i, 1] := blok;
          PLANSZA[i, 2] := 0;
          k := 1;
        end;
        bezpiecznik := bezpiecznik + 1;
        if bezpiecznik > 10 then
          k := 1;
      end;
    end;
    { wstawienie pierscieni }
    if oczekujacePierscienie > 0 then
    begin
      oczekujacePierscienie := oczekujacePierscienie - 1;
      k := 0;
      c := 1;
      while k = 0 do
      begin
        if (PLANSZA[25 + (50 * c), 1] = blokZew) or
          (PLANSZA[26 + (50 * c), 1] = blokZew) or
          (PLANSZA[2475 - (50 * c), 1] = blokZew) or
          (PLANSZA[2476 - (50 * c), 1] = blokZew) or (PLANSZA[1251 + c, 1] = blokZew) or
          (PLANSZA[1201 + c, 1] = blokZew) or (PLANSZA[1250 - c, 1] = blokZew) or
          (PLANSZA[1300 - c, 1] = blokZew) then
          c := c + 1
        else
          k := 1;
        if c > 22 then
          k := 1;
      end;
      for i := c to (50 - c) do
      begin
        PLANSZA[(c * 50) + i, 1] := blokZew;
        PLANSZA[(c * 50) + i, 2] := (-1);
        PLANSZA[2450 - (c * 50) + i, 1] := blokZew;
        PLANSZA[2450 - (c * 50) + i, 2] := (-1);
        PLANSZA[2501 - (i * 50) + c, 1] := blokZew;
        PLANSZA[2501 - (i * 50) + c, 2] := (-1);
        PLANSZA[2500 - (i * 50) + (50 - c), 1] := blokZew;
        PLANSZA[2500 - (i * 50) + (50 - c), 2] := (-1);
      end;
    end;
    { przyciecie wezy }
    for i := CZERWONY to FIOLETOWY do
    begin
      if kierunekGracza[i] > 0 then
      begin
        if ((PLANSZA[weze[i]^.nr, 1] > 28) and (PLANSZA[weze[i]^.nr, 1] < 31)) or
          (PLANSZA[weze[i]^.nr, 1] = 40) then
        begin
          if weze[i]^.nr mod 50 = 0 then
          begin
            kierunekGracza[i] := SKUTY;
            weze[i]^.nr := weze[i]^.nr - 50;              { NIE OGARNIAM!!! }
          end
          else
            kierunekGracza[i] := SKUTY;
        end
        else
        begin
          { usuwanie kolejnych segmentow }
          tymWsk := weze[i];
          if (tymWsk^.wsk <> nil) then
            while (tymWsk^.wsk <> nil) do
            begin
              if ((PLANSZA[tymWsk^.nr, 1] > 28) and
                (PLANSZA[tymWsk^.nr, 1] < 31)) or
                (PLANSZA[tymWsk^.nr, 1] = 40) then
              begin
                repeat
                  if PLANSZA[PozycjaKonca(weze[i]), 1] = i then
                    PLANSZA[PozycjaKonca(weze[i]), 1] := (-1);
                  UsunOstatniElement(tymWsk)
                until tymWsk^.wsk = nil;
                UsunOstatniElement(weze[i]);
                break;
              end
              else
                tymWsk := tymWsk^.wsk;
            end;
          { k := 0;
          while k = 0 do
          begin
            if ((PLANSZA[PozycjaKonca(weze[i]), 1] > 28) and
              (PLANSZA[PozycjaKonca(weze[i]), 1] < 31)) or
              (PLANSZA[PozycjaKonca(weze[i]), 1] = 40) then
              UsunOstatniElement(weze[i])
            else
              k := 1;
          end; }
        end;
      end;
    end;
  end;
end;

procedure WykonajRuch();
var
  i, j: integer;
begin
  for  i := CZERWONY to FIOLETOWY do
  begin
    if (kierunekGracza[i] <> SKUTY) and (nastepnaPozycja[i] <> (-1)) then
    begin
      { zebranie bonusow }
      if PLANSZA[nastepnaPozycja[i], 1] = jedzenie then
      begin
        kolejkaSegmenty[i] := kolejkaSegmenty[i] + 1;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = jedzenie3 then
      begin
        kolejkaSegmenty[i] := kolejkaSegmenty[i] + 3;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = speed then
      begin
        moceGracza[i, 1] := 17 * 4 * szybkoscGry;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = slow then
      begin
        for  j := CZERWONY to FIOLETOWY do
        begin
          if i <> j then
            moceGracza[j, 2] := 17 * 4 * szybkoscGry;
        end;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = spirit then
      begin
        moceGracza[i, 3] := 17 * 4 * szybkoscGry;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = zmianaKierunku then
      begin
        for  j := CZERWONY to FIOLETOWY do
        begin
          if i <> j then
            moceGracza[j, 4] := 17 * 4 * szybkoscGry;
        end;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = generujSciane then
      begin
        oczekujaceBloki := oczekujaceBloki + 1;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end
      else if PLANSZA[nastepnaPozycja[i], 1] = generujPierscien then
      begin
        oczekujacePierscienie := oczekujacePierscienie + 1;
        PLANSZA[nastepnaPozycja[i], 1] := (-1);
        PLANSZA[nastepnaPozycja[i], 2] := 0;
      end;
      { usuniecie koncow wezy z PLANSZY  / nowe pozycje glow w listach }
      if kolejkaSegmenty[i] > 0 then
      begin
        kolejkaSegmenty[i] := kolejkaSegmenty[i] - 1;
        PrzesunWeza(weze[i], nastepnaPozycja[i]);
      end
      else
      begin
        PLANSZA[PozycjaKonca(weze[i]), 1] := (-1);
        UsunOstatniElement(weze[i]);
        PrzesunWeza(weze[i], nastepnaPozycja[i]);
      end;
    end;
  end;
end;

procedure SprawdzKolizje();
var
  i, j: integer;
  tymWsk: wazWsk;
begin
  for  i := CZERWONY to FIOLETOWY do
  begin
    if (kierunekGracza[i] <> SKUTY) and (nastepnaPozycja[i] <> (-1)) then
    begin
      if PLANSZA[weze[i]^.nr, 1] <= 0 then
      begin
        PLANSZA[weze[i]^.nr, 1] := i;
        PLANSZA[weze[i]^.nr, 2] := kierunekGracza[i];
        tymWsk := weze[i];
        if tymWsk^.wsk <> nil then
        begin
          tymWsk := tymWsk^.wsk;
          PLANSZA[tymWsk^.nr, 2] := 0;
        end;
      end
      else if (PLANSZA[weze[i]^.nr, 1] >= CZERWONY) and
        (PLANSZA[weze[i]^.nr, 1] <= FIOLETOWY) and (PLANSZA[weze[i]^.nr, 2] <= 0) then
      begin
        PLANSZA[weze[i]^.nr, 1] := bialePole;
        kierunekGracza[i] := SKUTY;
      end
      else if (PLANSZA[weze[i]^.nr, 1] >= CZERWONY) and
        (PLANSZA[weze[i]^.nr, 1] <= FIOLETOWY) and (PLANSZA[weze[i]^.nr, 2] > 0) then
      begin
        for  j := CZERWONY to FIOLETOWY do
          if (weze[i]^.nr = weze[j]^.nr) then
          begin
            PLANSZA[weze[i]^.nr, 1] := bialePole;
            kierunekGracza[i] := SKUTY;
            kierunekGracza[j] := SKUTY;
          end;
      end;
    end;
  end;
end;

procedure SprawdzPole();
var
  P: Text;
  i, c, k: integer;
  s1, s2: string;
begin
  if stanGry = GRAJ then
    if trybGry = TRYBWOLNY then
    begin
      c := 0;
      for i := CZERWONY to FIOLETOWY do
        if (tabelaGraczy1[i] > 0) then
          c := c + 1;
      for i := CZERWONY to FIOLETOWY do
        if (tabelaGraczy1[i] > 0) and (kierunekGracza[i] = SKUTY) then
          c := c - 1;
      if (c = 0) then
      begin
        SDL_DELAY(2000);
        ResetujPlansze();
      end
      else if (c = 1) and (Pos('NIESKONCZONOSC', warunekWygranej) = 0) then
      begin
        for i := CZERWONY to FIOLETOWY do
          if (tabelaGraczy1[i] > 0) and (kierunekGracza[i] > 0) then
            wynikGracza[i] := wynikGracza[i] + 1;
        SDL_DELAY(2000);
        k := 0;
        for i := CZERWONY to FIOLETOWY do
          if wynikGracza[i] >= iloscRund then
            k := i;
        if k = 0 then
          ResetujPlansze()
        else
          stanGry := KONIECGRY;
      end;
    end
    else
    begin
      if kierunekGracza[CZERWONY] = SKUTY then
        stanGry := KONIECGRY
      else
      { KAMPANIA - WARUNKI WYGRANEJ }
      if Pos('DLUGOSC', warunekWygranej) <> 0 then
      begin
        if DlugoscWeza(weze[CZERWONY]) >=
          StrToInt(Copy(warunekWygranej, 9, (Length(warunekWygranej) - 8))) then
          stanGry := WYGRANA;
      end
      else if Pos('CZAS', warunekWygranej) <> 0 then
      begin
        if Trunc(SEKUNDNIK * 13 / RAMKA / szybkoscGry) >=
          StrToInt(Copy(warunekWygranej, 6, (Length(warunekWygranej) - 5))) then
          stanGry := WYGRANA;
      end;
      { odblokowanie kolejnej planszy }
      if stanGry = WYGRANA then
      begin

      end;
    end;
end;

procedure SYMULUJ();
var
  i, j, k, n, pozStart, x, y, dz, bezpiecznik, pop: integer;
  slepePola: array[52..2449] of integer;
  { wspolna tablica dla pol, z ktorych nie mozna skorzystac (slepe zaulki) 0/1 - wolne/zablokowane }
  tymSciezka: wazWsk;
  sciezka: array[1..2] of wazWsk;
  { tutaj wazWsk to kolejne pola sciezki - 1/2 - aktualne/tymczasowe }
begin
  for  i := CZERWONY to FIOLETOWY do
    if (tabelaGraczy1[i] = 2) and (kierunekGracza[i] <> SKUTY) and
      (stanGry = GRAJ) and (ruchGracza[i, 2] >= ruchGracza[i, 1]) then
    begin
      { ustalenie celu }
      if (celGracza[i] = 0) or ((PLANSZA[celGracza[i], 1] <> jedzenie) and
        (PLANSZA[celGracza[i], 1] <> jedzenie3)) then
      begin
        randomize();
        k := random(2397) + 52;
        for j := k to 2449 do
          if ((PLANSZA[j, 1] = jedzenie) or (PLANSZA[j, 1] = jedzenie3)) and
            (celGracza[i] = 0) then
            celGracza[i] := j;
        for j := 52 to (k - 1) do
          if ((PLANSZA[j, 1] = jedzenie) or (PLANSZA[j, 1] = jedzenie3)) and
            (celGracza[i] = 0) then
            celGracza[i] := j;
        { przy braku pozywienia na planszy szuka losowege puste pole }
        if celGracza[i] = 0 then
        begin
          for j := k to 2449 do
            if (PLANSZA[j, 1] <= 0) and (celGracza[i] = 0) then
              celGracza[i] := j;
          for j := 51 to (k - 1) do
            if (PLANSZA[j, 1] <= 0) and (celGracza[i] = 0) then
              celGracza[i] := j;
        end;
      end;
      New(sciezka[1]);
      sciezka[1]^.nr := 0;
      sciezka[1]^.wsk := nil;
      { sprawdzenie czy cel jest w odleglosci 1 kratki }
      if (weze[i]^.nr - 50 = celGracza[i]) or (weze[i]^.nr - 1 = celGracza[i]) or
        (weze[i]^.nr + 50 = celGracza[i]) or (weze[i]^.nr + 1 = celGracza[i]) then
      begin
        sciezka[1]^.nr := celGracza[i];
        celGracza[i] := 0;
      end
      { sprawdzenie 4 kierunkow }
      else
      begin
        for j := GORA to LEWO do
        begin
          { resetowanie zmiennych }
          for k := 52 to 2449 do
            slepePola[k] := 0;
          New(sciezka[2]);
          sciezka[2]^.nr := 0;
          sciezka[2]^.wsk := nil;
          { ustalenie czy rozpoczecie trasy jest mozliwe }
          if (j = GORA) and ((PLANSZA[weze[i]^.nr - 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 50, 1] <> bialePole) then
            sciezka[2]^.nr := weze[i]^.nr - 50
          else if (j = PRAWO) and ((PLANSZA[weze[i]^.nr + 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 1, 1] <> bialePole) then
            sciezka[2]^.nr := weze[i]^.nr + 1
          else if (j = DOL) and ((PLANSZA[weze[i]^.nr + 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 50, 1] <> bialePole) then
            sciezka[2]^.nr := weze[i]^.nr + 50
          else if (j = LEWO) and ((PLANSZA[weze[i]^.nr - 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 1, 1] <> bialePole) then
            sciezka[2]^.nr := weze[i]^.nr - 1;
          pozStart := sciezka[2]^.nr;
          { glowna petla algorytmu - generuje sciezke }
          if sciezka[2]^.nr <> 0 then
          begin
            k := 0;
            bezpiecznik := 0; { !!!!!!!!!!!!! }
            while k = 0 do
            begin
              bezpiecznik := bezpiecznik + 1; { !!!!!!!!!!!!! }
              if bezpiecznik > 2000 then
                k := (-1); { !!!!!!!!!!!!! }
              if sciezka[2] <> nil then
              begin
                x := (celGracza[i] mod 50) - (sciezka[2]^.nr mod 50);
                y := Trunc(celGracza[i] / 50) - Trunc(sciezka[2]^.nr / 50);
                if sciezka[2] <> nil then
                begin
                  if sciezka[2]^.wsk <> nil then
                    pop := sciezka[2]^.wsk^.nr
                  else
                    pop := 0;
                end
                else
                  pop := 0;
                dz := 0;
                { ruch do przodu }
                { x = 0 / y < 0 }
                if (x = 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x = 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                else if (x = 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                else if (x = 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                { x = 0 / y > 0 }
                else if (x = 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                else if (x = 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                else if (x = 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                else if (x = 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                { x < 0 / y < 0 }
                else if (x <= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                else if (x <= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x <= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                else if (x <= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                { x > 0 / y < 0 }
                else if (x >= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x >= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                else if (x >= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                else if (x >= 0) and (y < 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                { x > 0 / y > 0 }
                else if (x >= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                else if (x >= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                else if (x >= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x >= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                { x < 0 / y > 0 }
                else if (x <= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                else if (x <= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                else if (x <= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x <= 0) and (y > 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                { x < 0 / y = 0 }
                else if (x < 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                else if (x < 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                else if (x < 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x < 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                { x > 0 / y = 0 }
                else if (x >= 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr + 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <> bialePole) and
                  (sciezka[2]^.nr + 1 <> pop) and
                  (slepePola[sciezka[2]^.nr + 1] = 0) then
                  dz := 1
                else if (x >= 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr + 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <> bialePole) and
                  (sciezka[2]^.nr + 50 <> pop) and
                  (slepePola[sciezka[2]^.nr + 50] = 0) then
                  dz := 50
                else if (x >= 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr - 50, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <> bialePole) and
                  (sciezka[2]^.nr - 50 <> pop) and
                  (slepePola[sciezka[2]^.nr - 50] = 0) then
                  dz := (-50)
                else if (x >= 0) and (y = 0) and
                  ((PLANSZA[sciezka[2]^.nr - 1, 1] < CZERWONY) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] > teleport)) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <> bialePole) and
                  (sciezka[2]^.nr - 1 <> pop) and
                  (slepePola[sciezka[2]^.nr - 1] = 0) then
                  dz := (-1)
                { warunek na brak drogi }
                else if (sciezka[2]^.nr = pozStart) and
                  ((((PLANSZA[sciezka[2]^.nr + 50, 1] >= CZERWONY) and
                  (PLANSZA[sciezka[2]^.nr + 50, 1] <= teleport)) or
                  (PLANSZA[sciezka[2]^.nr + 50, 1] = bialePole)) or
                  (slepePola[sciezka[2]^.nr + 50] = 1)) and
                  ((((PLANSZA[sciezka[2]^.nr - 50, 1] >= CZERWONY) and
                  (PLANSZA[sciezka[2]^.nr - 50, 1] <= teleport)) or
                  (PLANSZA[sciezka[2]^.nr - 50, 1] = bialePole)) or
                  (slepePola[sciezka[2]^.nr - 50] = 1)) and
                  ((((PLANSZA[sciezka[2]^.nr + 1, 1] >= CZERWONY) and
                  (PLANSZA[sciezka[2]^.nr + 1, 1] <= teleport)) or
                  (PLANSZA[sciezka[2]^.nr + 1, 1] = bialePole)) or
                  (slepePola[sciezka[2]^.nr + 1] = 1)) and
                  ((((PLANSZA[sciezka[2]^.nr - 1, 1] >= CZERWONY) and
                  (PLANSZA[sciezka[2]^.nr - 1, 1] <= teleport)) or
                  (PLANSZA[sciezka[2]^.nr - 1, 1] = bialePole)) or
                  (slepePola[sciezka[2]^.nr - 1] = 1)) then
                  k := (-1)
                { cofanie }
                else if sciezka[2]^.nr <> celGracza[i] then
                begin
                  slepePola[sciezka[2]^.nr] := 1;
                  tymSciezka := sciezka[2];
                  sciezka[2] := sciezka[2]^.wsk;
                  Dispose(tymSciezka);
                end;
                { testowe do usuniecia }
                if sciezka[2] <> nil then
                  slepePola[sciezka[2]^.nr] := 1;
                { dodanie elementu do listy }
                if dz <> 0 then
                begin
                  New(tymSciezka);
                  tymSciezka^.nr := sciezka[2]^.nr + dz;
                  tymSciezka^.wsk := sciezka[2];
                  sciezka[2] := tymSciezka;
                end;
                { warunek na dojscie do celu }
                if sciezka[2] <> nil then
                begin
                  if sciezka[2]^.nr = celGracza[i] then
                    k := 1;
                end
                else
                  k := (-1);
              end;
              { !!!RYSOWANIE SCIEZKI!!! }
              if (sciezka[2] <> nil) and (trybSymulacji = True) then
                if sciezka[2]^.nr <> 0 then
                begin
                  DRAW();
                  for n := 52 to 2449 do
                    if slepePola[n] = 1 then
                    begin
                      x := (n - 1) mod 50;
                      y := (Trunc((n) / 50));
                      Wytnij2(kw, generujSciane, 0);
                      poz^.x := (x * 12) + 150;
                      poz^.y := (y * 12) + 20;
                      SDL_BLITSURFACE(sprite, kw, ekran, poz);
                    end;
                  x := ((sciezka[2]^.nr) - 1) mod 50;
                  y := (Trunc((sciezka[2]^.nr) / 50));
                  Wytnij2(kw, bialePole, 1);
                  poz^.x := (x * 12) + 150;
                  poz^.y := (y * 12) + 20;
                  SDL_BLITSURFACE(sprite, kw, ekran, poz);
                  x := ((celGracza[i]) - 1) mod 50;
                  y := (Trunc((celGracza[i]) / 50));
                  Wytnij2(kw, generujPierscien, 1);
                  poz^.x := (x * 12) + 150;
                  poz^.y := (y * 12) + 20;
                  SDL_BLITSURFACE(sprite, kw, ekran, poz);
                  SDL_FLIP(ekran);
                  SDL_DELAY(5);
                end;
              { !!!!!!!!!!!!!!!!!!!!!! }
            end;
            if sciezka[2] <> nil then
              if k = (-1) then
                sciezka[2]^.nr := 0;
          end;
          { porownanie sciezki tymczasowej z glowna i ewentualna podmiana }
          if sciezka[2] <> nil then
            if ((sciezka[1]^.nr = 0) and (sciezka[2]^.nr <> 0)) or
              ((sciezka[2]^.nr <> 0) and (DlugoscWeza(sciezka[1]) >
              DlugoscWeza(sciezka[2]))) then
              sciezka[1] := sciezka[2];
        end;
      end;
      { przewiniecie listy do 1 elementu }
      if sciezka[1]^.wsk <> nil then
        while sciezka[1]^.wsk <> nil do
          sciezka[1] := sciezka[1]^.wsk;
      { ostateczne ustalenie kierunku }
      if sciezka[1]^.nr <> 0 then
      begin
        if kierunekGracza[i] = GORA then
        begin
          if pozycjaKonca(sciezka[1]) = (weze[i]^.nr + 1) then
            klawiszGracza[i] := PRAWO
          else if pozycjaKonca(sciezka[1]) = (weze[i]^.nr - 1) then
            klawiszGracza[i] := LEWO;
        end
        else if kierunekGracza[i] = DOL then
        begin
          if pozycjaKonca(sciezka[1]) = (weze[i]^.nr + 1) then
            klawiszGracza[i] := LEWO
          else if pozycjaKonca(sciezka[1]) = (weze[i]^.nr - 1) then
            klawiszGracza[i] := PRAWO;
        end
        else if kierunekGracza[i] = PRAWO then
        begin
          if pozycjaKonca(sciezka[1]) = (weze[i]^.nr - 50) then
            klawiszGracza[i] := LEWO
          else if pozycjaKonca(sciezka[1]) = (weze[i]^.nr + 50) then
            klawiszGracza[i] := PRAWO;
        end
        else if kierunekGracza[i] = LEWO then
        begin
          if pozycjaKonca(sciezka[1]) = (weze[i]^.nr + 50) then
            klawiszGracza[i] := LEWO
          else if pozycjaKonca(sciezka[1]) = (weze[i]^.nr - 50) then
            klawiszGracza[i] := PRAWO;
        end;
      end
      else
        { przy braku dostepu do celu unika kolizji }
      begin
        if kierunekGracza[i] = GORA then
        begin
          if ((PLANSZA[weze[i]^.nr - 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 50, 1] <> bialePole) then
            klawiszGracza[i] := 0
          else if ((PLANSZA[weze[i]^.nr + 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 1, 1] <> bialePole) then
            klawiszGracza[i] := PRAWO
          else if ((PLANSZA[weze[i]^.nr - 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 1, 1] <> bialePole) then
            klawiszGracza[i] := LEWO;
        end
        else if kierunekGracza[i] = DOL then
        begin
          if ((PLANSZA[weze[i]^.nr + 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 50, 1] <> bialePole) then
            klawiszGracza[i] := 0
          else if ((PLANSZA[weze[i]^.nr + 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 1, 1] <> bialePole) then
            klawiszGracza[i] := LEWO
          else if ((PLANSZA[weze[i]^.nr - 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 1, 1] <> bialePole) then
            klawiszGracza[i] := PRAWO;
        end
        else if kierunekGracza[i] = PRAWO then
        begin
          if ((PLANSZA[weze[i]^.nr + 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 1, 1] <> bialePole) then
            klawiszGracza[i] := 0
          else if ((PLANSZA[weze[i]^.nr + 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 50, 1] <> bialePole) then
            klawiszGracza[i] := PRAWO
          else if ((PLANSZA[weze[i]^.nr - 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 50, 1] <> bialePole) then
            klawiszGracza[i] := LEWO;
        end
        else if kierunekGracza[i] = LEWO then
        begin
          if ((PLANSZA[weze[i]^.nr - 1, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 1, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 1, 1] <> bialePole) then
            klawiszGracza[i] := 0
          else if ((PLANSZA[weze[i]^.nr + 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr + 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr + 50, 1] <> bialePole) then
            klawiszGracza[i] := LEWO
          else if ((PLANSZA[weze[i]^.nr - 50, 1] < CZERWONY) or
            (PLANSZA[weze[i]^.nr - 50, 1] > teleport)) and
            (PLANSZA[weze[i]^.nr - 50, 1] <> bialePole) then
            klawiszGracza[i] := PRAWO;
        end;
        celGracza[i] := 0;
      end;
      { ustalenie nowego celu po dotarciu }
      if (sciezka[1]^.nr - 50 = celGracza[i]) or (sciezka[1]^.nr - 1 = celGracza[i]) or
        (sciezka[1]^.nr + 50 = celGracza[i]) or (sciezka[1]^.nr + 1 = celGracza[i]) or
        (sciezka[1]^.nr = 0) then
      begin
        { celGracza[i] := 0; }
      end;
      { obsluga zamiany klawiszy }
      if moceGracza[i, 4] > 0 then
      begin
        { 10% szanszy na pomylke }
        randomize();
        if random(10) <> 6 then
          if klawiszGracza[i] = LEWO then
            klawiszGracza[i] := PRAWO
          else if klawiszGracza[i] = PRAWO then
            klawiszGracza[i] := LEWO;
      end;
    end;
end;

end.
