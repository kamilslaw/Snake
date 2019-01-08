unit lista;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils;

type
  wazWsk = ^wazEl;

  wazEl = record
    nr: integer;
    wsk: wazWsk;
  end;

procedure DodajElement(var wskaznik: wazWsk; nrPozycji: integer);
procedure UsunOstatniElement(var wskaznik: wazWsk);
function PozycjaKonca(wskaznik: wazWsk): integer;
function DlugoscWeza(wskaznik: wazWsk): integer;
procedure PrzesunWeza(var wskaznik: wazWsk; nPoz: integer);

implementation

procedure DodajElement(var wskaznik: wazWsk; nrPozycji: integer);
var
  tym, nowy: wazWsk;
begin
  tym := wskaznik;
  if tym^.wsk <> nil then
    while tym^.wsk <> nil do
      tym := tym^.wsk;
  New(nowy);
  nowy^.nr := nrPozycji;
  tym^.wsk := nowy;
  nowy^.wsk := nil;
end;

procedure UsunOstatniElement(var wskaznik: wazWsk);
var
  tym, tymPop: wazWsk;
begin
  tym := wskaznik;
  if tym^.wsk <> nil then
    while tym^.wsk <> nil do
      tym := tym^.wsk;
  tymPop := wskaznik;
  if tymPop^.wsk <> nil then
    while tymPop^.wsk <> tym do
      tymPop := tymPop^.wsk;
  tymPop^.wsk := nil;
  Dispose(tym);
end;

function PozycjaKonca(wskaznik: wazWsk): integer;
var
  tym: wazWsk;
begin
  tym := wskaznik;
  if tym^.wsk <> nil then
    while tym^.wsk <> nil do
      tym := tym^.wsk;
  PozycjaKonca := tym^.nr;
end;

function DlugoscWeza(wskaznik: wazWsk): integer;
var
  tym: wazWsk;
  i: integer;
begin
  tym := wskaznik;
  i := 1;
  if tym^.wsk <> nil then
    while tym^.wsk <> nil do
    begin
      tym := tym^.wsk;
      i := i + 1;
    end;
  DlugoscWeza := i;
end;

procedure PrzesunWeza(var wskaznik: wazWsk; nPoz: integer);
var
  tym: wazWsk;
begin
  New(tym);
  tym^.nr := nPoz;
  tym^.wsk := wskaznik;
  wskaznik := tym;
end;

end.
