program snake;

uses
  Classes,
  SysUtils,
  CRT,
  SDL,
  SDL_TTF,
  stale,
  gra,
  lista;

var
  petla: boolean = False;
  trybGry, mx, my: integer;
  tymParametryMapy: string;

  procedure ZACZNIJ_GRE();
  begin
    if trybGry = KAMPANIA then
      ROZPOCZNIJ_GRE(KAMPANIA, aktualnaMapa, parametryMapy)
    else
    begin
      if (tabelaGraczy[CZERWONY] > 0) or (tabelaGraczy[ZIELONY] > 0) or
        (tabelaGraczy[NIEBIESKI] > 0) or (tabelaGraczy[FIOLETOWY] > 0) then
      begin
        tymParametryMapy := 'SZYBKOSC:' + IntToStr(szybkoscGry) + '#';
        if tabelaGraczy[CZERWONY] > 0 then
          tymParametryMapy :=
            tymParametryMapy + 'CZERWONY:' + IntToStr(
            tabelaGraczy[CZERWONY]) + '#';
        if tabelaGraczy[ZIELONY] > 0 then
          tymParametryMapy :=
            tymParametryMapy + 'ZIELONY:' + IntToStr(
            tabelaGraczy[ZIELONY]) + '#';
        if tabelaGraczy[NIEBIESKI] > 0 then
          tymParametryMapy :=
            tymParametryMapy + 'NIEBIESKI:' + IntToStr(
            tabelaGraczy[NIEBIESKI]) + '#';
        if tabelaGraczy[FIOLETOWY] > 0 then
          tymParametryMapy :=
            tymParametryMapy + 'FIOLETOWY:' + IntToStr(
            tabelaGraczy[FIOLETOWY]) + '#';
        ROZPOCZNIJ_GRE(TRYBWOLNY, aktualnaMapa, tymParametryMapy);
      end;
    end;
  end;

  procedure RysujStrzalki(x, y, odleglosc: integer);
  begin
    Wytnij(kw, strzL1);
    poz^.x := x;
    poz^.y := y;
    poz^.w := kw^.w;
    poz^.h := kw^.h;
    SDL_BLITSURFACE(sprite, kw, ekran, poz);
    Wytnij(kw, strzL2);
    poz^.x := x + 12;
    poz^.y := y - 12;
    poz^.w := kw^.w;
    poz^.h := kw^.h;
    SDL_BLITSURFACE(sprite, kw, ekran, poz);
    Wytnij(kw, strzP1);
    poz^.x := x + 12 + odleglosc;
    poz^.y := y;
    poz^.w := kw^.w;
    poz^.h := kw^.h;
    SDL_BLITSURFACE(sprite, kw, ekran, poz);
    wytnij(kw, strzP2);
    poz^.x := x + odleglosc;
    poz^.y := y - 12;
    poz^.w := kw^.w;
    poz^.h := kw^.h;
    SDL_BLITSURFACE(sprite, kw, ekran, poz);
  end;

  procedure WypiszGracza(gracz, x, y: integer);
  begin
    if gracz = CZERWONY then
    begin
      kolor1^.r := 255;
      kolor1^.g := 0;
      kolor1^.b := 0;
    end
    else if gracz = ZIELONY then
    begin
      kolor1^.r := 0;
      kolor1^.g := 255;
      kolor1^.b := 0;
    end
    else if gracz = NIEBIESKI then
    begin
      kolor1^.r := 0;
      kolor1^.g := 0;
      kolor1^.b := 255;
    end
    else if gracz = FIOLETOWY then
    begin
      kolor1^.r := 180;
      kolor1^.g := 0;
      kolor1^.b := 255;
    end;
    poz^.x := x;
    poz^.y := y;
    napis := TTF_RenderText_Blended(czcionkad,
      PChar(tekst[tabelaGraczy[gracz] + 8]), kolor1^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
    kolor1^.r := 255;
    kolor1^.g := 255;
    kolor1^.b := 255;
  end;

  function JestKlikniecie(x, y, mx, my, rodzaj: integer): boolean;
    { rodzaj - lewo, prawo }
  begin
    if rodzaj = LEWO then
    begin
      if ((mx >= x) and (mx <= (x + 12)) and (my >= y) and (my <= (y + 24))) or
        ((mx >= (x + 12)) and (mx <= (x + 24)) and (my >= (y - 12)) and
        (my <= (y + 36))) then
        JestKlikniecie := True
      else
        JestKlikniecie := False;
    end
    else if rodzaj = PRAWO then
    begin
      y := y - 12;
      if ((mx >= x) and (mx <= (x + 12)) and (my >= y) and (my <= (y + 48))) or
        ((mx >= (x + 12)) and (mx <= (x + 24)) and (my >= (y + 12)) and
        (my <= (y + 36))) then
        JestKlikniecie := True
      else
        JestKlikniecie := False;
    end;
  end;

  procedure Rysuj();
  var
    P: Text;
    s1: string;
    i, tx, ty, j, kolorPodglad: integer;
  begin
    wytnij(kw, caloscRamka);
    SDL_FillRect(ekran, kw, $333333);
    wytnij(kw, calosc);
    SDL_FillRect(ekran, kw, $000000); { tymczasowe - do usuniecia }
    { tryb gry }
    kolor1^.r := 255;
    kolor1^.g := 255;
    kolor1^.b := 255;
    poz^.x := 134;
    poz^.y := 40;
    poz^.w := 130;
    poz^.h := 300;
    napis := TTF_RenderText_Blended(czcionkad, PChar(tekst[5]), kolor1^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
    poz^.y := 100;
    napis := TTF_RenderText_Blended(czcionkad, PChar(tekst[trybGry]), kolor1^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
    RysujStrzalki(100, 100, 200);
    { strzalki do nazwy mapy }
    RysujStrzalki(100, 190, 400);
    wytnij(kw, rozpocznijGre);
    SDL_FillRect(ekran, kw, $442244);
    poz^.x := 618;
    poz^.y := 518;
    napis := TTF_RenderText_Blended(czcionkad, PChar(tekst[11]), kolor1^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
    { podglad mapy i informacje }
    wytnij(kw, podgladMapyRamka);
    SDL_FillRect(ekran, kw, $FF55FF);
    wytnij(kw, podgladMapy);
    SDL_FillRect(ekran, kw, $b5b5b5);
    { kampania }
    if trybGry = KAMPANIA then
    begin
      if popAktualnaMapa <> aktualnaMapa then
        ZaladujInfooMapie(KAMPANIA);
      { rysowanie podgladu }
      Assign(P, 'map/campaign/' + IntToStr(aktualnaMapa) + '.map');
      Reset(P);
      ReadLn(P, s1);
      while not EOF(P) do
      begin
        ReadLn(P, s1);
        i := StrToInt(Copy(s1, 1, Pos(':', s1) - 1));
        j := StrToInt(Copy(s1, Pos(':', s1) + 1, 2));
        ty := Trunc(i / 50);
        tx := i mod 50;
        kw^.x := (tx * 4) + 130;
        kw^.y := (ty * 4) + 360;
        kw^.w := 4;
        kw^.h := 4;
        if j = 10 then
          kolorPodglad := $d22828
        else if j = 11 then
          kolorPodglad := $60d228
        else if j = 12 then
          kolorPodglad := $287cd2
        else if j = 13 then
          kolorPodglad := $a028d2
        else if j = 30 then
          kolorPodglad := $63634b
        else if j = 31 then
          kolorPodglad := $0f3273;
        SDL_FillRect(ekran, kw, kolorPodglad);
      end;
      Close(P);
    end
    { tryb wolny }
    else
    begin
      if popAktualnaMapa <> aktualnaMapa then
        ZaladujInfooMapie(TRYBWOLNY);
      { rysowanie podgladu }
      Assign(P, 'map/' + IntToStr(aktualnaMapa) + '.map');
      Reset(P);
      ReadLn(P, s1);
      ReadLn(P, s1);
      ReadLn(P, s1);
      while not EOF(P) do
      begin
        ReadLn(P, s1);
        i := StrToInt(Copy(s1, 1, Pos(':', s1) - 1));
        j := StrToInt(Copy(s1, Pos(':', s1) + 1, 2));
        ty := Trunc(i / 50);
        tx := i mod 50;
        kw^.x := (tx * 4) + 130;
        kw^.y := (ty * 4) + 360;
        kw^.w := 4;
        kw^.h := 4;
        if j = 10 then
          kolorPodglad := $d22828
        else if j = 11 then
          kolorPodglad := $60d228
        else if j = 12 then
          kolorPodglad := $287cd2
        else if j = 13 then
          kolorPodglad := $a028d2
        else if j = 30 then
          kolorPodglad := $63634b
        else if j = 31 then
          kolorPodglad := $0f3273;
        SDL_FillRect(ekran, kw, kolorPodglad);
      end;
      { rysowanie kontrolek do obslugi parametrow }
      RysujStrzalki(630, 160, 80);
      napis := TTF_RenderText_Blended(czcionkad,
        PChar(IntToStr(szybkoscGry) + 'x'), kolor1^);
      poz^.x := 666;
      poz^.y := 158;
      SDL_BLITSURFACE(napis, nil, ekran, poz);
      RysujStrzalki(630, 270, 120);
      RysujStrzalki(630, 330, 120);
      RysujStrzalki(630, 390, 120);
      RysujStrzalki(630, 450, 120);
      WypiszGracza(CZERWONY, 666, 268);
      WypiszGracza(ZIELONY, 666, 328);
      WypiszGracza(NIEBIESKI, 666, 388);
      WypiszGracza(FIOLETOWY, 666, 448);
    end;
    poz^.x := 134;
    poz^.y := 190;
    poz^.w := 200;
    poz^.h := 800;
    napis := TTF_RenderText_Blended(czcionkad, PChar(nazwaMapy), kolor1^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);
    poz^.x := 134;
    poz^.y := 260;
    poz^.w := 200;
    poz^.h := 800;
    napis := TTF_RenderText_Blended(czcionkam, PChar(opisMapy), kolor1^);
    SDL_BLITSURFACE(napis, nil, ekran, poz);

    SDL_FLIP(ekran);
  end;

begin
  { Inicjacja SDL-a }
  SDL_INIT(SDL_INIT_VIDEO);
  TTF_INIT();
  LadowanieUstawien();
  SDL_WM_SetCaption('SNAKE', nil);
  ekran := SDL_SETVIDEOMODE(900, 640, 32, USTAWIENIAVIDEO);
  if ekran = nil then
    HALT;

  new(zdarzenie);
  new(kolor1);
  new(kolor2);
  new(czcionkad);
  new(czcionkam);
  new(kw);
  new(poz);
  czcionkad := TTF_OpenFont('times.ttf', 28);
  czcionkam := TTF_OpenFont('times.ttf', 16);
  sprite := SDL_LoadBMP('img/sprites.bmp');
  trybGry := KAMPANIA;

  Rysuj();

  { PĘTLA GRY }
  while petla = False do
  begin
    if SDL_POLLEVENT(zdarzenie) = 1 then
    begin
      case zdarzenie^.type_ of
        SDL_MOUSEBUTTONDOWN:
        begin
          mx := zdarzenie^.motion.x;
          my := zdarzenie^.motion.y;
          { tryb gry }
          if JestKlikniecie(100, 100, mx, my, LEWO) or
            JestKlikniecie(300, 100, mx, my, PRAWO) then
            if trybGry = KAMPANIA then
            begin
              trybGry := TRYBWOLNY;
              aktualnaMapa := 1;
              popAktualnaMapa := 0;
            end
            else
            begin
              trybGry := KAMPANIA;
              aktualnaMapa := nrOdblokMapy;
              popAktualnaMapa := 0;
            end;
          { mapa }
          if JestKlikniecie(100, 190, mx, my, LEWO) then
            if trybGry = KAMPANIA then
            begin
              if aktualnaMapa = 1 then
                aktualnaMapa := nrOdblokMapy
              else
                aktualnaMapa := aktualnaMapa - 1;
            end
            else
            begin
              if aktualnaMapa = 1 then
                aktualnaMapa := ilMapTrybWolny
              else
                aktualnaMapa := aktualnaMapa - 1;
            end;
          if JestKlikniecie(500, 190, mx, my, PRAWO) then
            if trybGry = KAMPANIA then
            begin
              if aktualnaMapa = nrOdblokMapy then
                aktualnaMapa := 1
              else
                aktualnaMapa := aktualnaMapa + 1;
            end
            else
            begin
              if aktualnaMapa = ilMapTrybWolny then
                aktualnaMapa := 1
              else
                aktualnaMapa := aktualnaMapa + 1;
            end;
          { ustawienia gry - gra dowolna }
          if trybGry = TRYBWOLNY then
          begin
            { szybkosc gry }
            if JestKlikniecie(630, 160, mx, my, LEWO) then
            begin
              if szybkoscGry = 1 then
                szybkoscGry := 3
              else
                szybkoscGry := szybkoscGry - 1;
            end
            else if JestKlikniecie(710, 160, mx, my, PRAWO) then
            begin
              if szybkoscGry = 3 then
                szybkoscGry := 1
              else
                szybkoscGry := szybkoscGry + 1;
            end;
            { rodzaj gracza - czerwony}
            if JestKlikniecie(630, 270, mx, my, LEWO) then
            begin
              if tabelaGraczy[CZERWONY] = 0 then
                tabelaGraczy[CZERWONY] := 2
              else
                tabelaGraczy[CZERWONY] := tabelaGraczy[CZERWONY] - 1;
            end
            else if JestKlikniecie(750, 270, mx, my, PRAWO) then
            begin
              if tabelaGraczy[CZERWONY] = 2 then
                tabelaGraczy[CZERWONY] := 0
              else
                tabelaGraczy[CZERWONY] := tabelaGraczy[CZERWONY] + 1;
            end;
            { zielony }
            if JestKlikniecie(630, 330, mx, my, LEWO) then
            begin
              if tabelaGraczy[ZIELONY] = 0 then
                tabelaGraczy[ZIELONY] := 2
              else
                tabelaGraczy[ZIELONY] := tabelaGraczy[ZIELONY] - 1;
            end
            else if JestKlikniecie(750, 330, mx, my, PRAWO) then
            begin
              if tabelaGraczy[ZIELONY] = 2 then
                tabelaGraczy[ZIELONY] := 0
              else
                tabelaGraczy[ZIELONY] := tabelaGraczy[ZIELONY] + 1;
            end;
            { niebieski }
            if JestKlikniecie(630, 390, mx, my, LEWO) then
            begin
              if tabelaGraczy[NIEBIESKI] = 0 then
                tabelaGraczy[NIEBIESKI] := 2
              else
                tabelaGraczy[NIEBIESKI] := tabelaGraczy[NIEBIESKI] - 1;
            end
            else if JestKlikniecie(750, 390, mx, my, PRAWO) then
            begin
              if tabelaGraczy[NIEBIESKI] = 2 then
                tabelaGraczy[NIEBIESKI] := 0
              else
                tabelaGraczy[NIEBIESKI] := tabelaGraczy[NIEBIESKI] + 1;
            end;
            { fioletowy }
            if JestKlikniecie(630, 450, mx, my, LEWO) then
            begin
              if tabelaGraczy[FIOLETOWY] = 0 then
                tabelaGraczy[FIOLETOWY] := 2
              else
                tabelaGraczy[FIOLETOWY] := tabelaGraczy[FIOLETOWY] - 1;
            end
            else if JestKlikniecie(750, 450, mx, my, PRAWO) then
            begin
              if tabelaGraczy[FIOLETOWY] = 2 then
                tabelaGraczy[FIOLETOWY] := 0
              else
                tabelaGraczy[FIOLETOWY] := tabelaGraczy[FIOLETOWY] + 1;
            end;
          end;
          { rozpocznij gre }
          if ((my >= 510) and (my <= 560) and (mx >= 610) and (mx <= 800)) then
          begin
            ZACZNIJ_GRE();
          end;
        end;
        SDL_KEYDOWN:
        begin
          if zdarzenie^.key.keysym.sym = SDLK_ESCAPE then
            petla := True;
          if zdarzenie^.key.keysym.sym = SDLK_RETURN then
            ZACZNIJ_GRE();
        end;
      end;
    end;
    Rysuj();
    SDL_DELAY(Round(RAMKA / 8));
  end;

  dispose(zdarzenie);
  dispose(kolor1);
  dispose(kolor2);
  dispose(kw);
  dispose(poz);
  TTF_CloseFont(czcionkad);
  TTF_CloseFont(czcionkam);
  TTF_Quit();
  SDL_FREESURFACE(ekran);
  SDL_QUIT;
end.
