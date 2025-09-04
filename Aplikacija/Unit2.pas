unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.ListView, FMX.Objects, FMX.Memo, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FMX.Controls.Presentation,Unit3;

type
  THome = class(TForm)
    lblIme: TLabel;
    lblPrezime: TLabel;
    lblKorIme: TLabel;
    lblUloga: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lvNalozi: TListView;
    btnOdjava: TButton;
    FDQueryRadnik: TFDQuery;
    FDQueryNalozi: TFDQuery;
    ImageControl1: TImageControl;
    Label1: TLabel;
    procedure btnOdjavaClick(Sender: TObject);
    procedure lvNaloziItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    FRadnikID: Integer;
  public
    procedure SetRadnikID(AID: Integer);
    procedure UcitajPodatke;
  end;

var
  Home: THome;

implementation
uses Unit1;
{$R *.fmx}



procedure THome.SetRadnikID(AID: Integer);
begin
  FRadnikID := AID;
end;

procedure THome.UcitajPodatke;
begin
  // 1. Učitavanje podataka o radniku
    FDQueryRadnik.Close;
  FDQueryRadnik.SQL.Text := 'SELECT Ime, Prezime, KorisnickoIme, Uloga FROM Radnik WHERE RadnikID = :RadnikID';
  FDQueryRadnik.ParamByName('RadnikID').AsInteger := FRadnikID;
  FDQueryRadnik.Open;

  lblIme.Text := FDQueryRadnik.FieldByName('Ime').AsString;
  lblPrezime.Text := FDQueryRadnik.FieldByName('Prezime').AsString;
  lblKorIme.Text := FDQueryRadnik.FieldByName('KorisnickoIme').AsString;
  lblUloga.Text := FDQueryRadnik.FieldByName('Uloga').AsString;

  // 2. Učitavanje naloga
  lvNalozi.Items.Clear;
  FDQueryNalozi.Close;
  FDQueryNalozi.SQL.Text := 'SELECT NalogID FROM ProizvodniNalog';
  FDQueryNalozi.Open;
  while not FDQueryNalozi.Eof do
  begin
    with lvNalozi.Items.Add do
    begin
    Text := 'Nalog ID: ' + FDQueryNalozi.FieldByName('NalogID').AsString;
    Tag := FDQueryNalozi.FieldByName('NalogID').AsInteger;
    end;
    FDQueryNalozi.Next;
  end;
end;


procedure THome.lvNaloziItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
          if AItem = nil then Exit;
  DetaljiNaloga.LoadNalog(AItem.Tag, FRadnikID);
  DetaljiNaloga.Show;
  Self.Hide;
end;



procedure THome.btnOdjavaClick(Sender: TObject);
begin
  Self.Hide;
  Login.edtKorisnickoIme.Text := '';
  Login.edtLozinka.Text := '';
  Login.lblPoruka.Text := '';
  Login.Show;
end;

end.

