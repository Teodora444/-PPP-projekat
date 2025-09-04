unit Unit4;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Memo, FMX.ListView, FMX.Objects,
  FMX.Controls.Presentation, FMX.ListView.Types, FMX.Memo.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ScrollBox,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.DatS,Unit5;

type
  TUputstvo = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    ListView1: TListView;
    btnZapocni: TButton;
    btnZavrsi: TButton;
    ellZapoceo: TEllipse;
    ellUToku: TEllipse;
    ellZavrseno: TEllipse;
    TimerUToku: TTimer;
    FDQuery1: TFDQuery;
    procedure btnZapocniClick(Sender: TObject);
    procedure btnZavrsiClick(Sender: TObject);
    procedure TimerUTokuTimer(Sender: TObject);
    procedure btnNazadClick(Sender: TObject);
    procedure btnKreirajIzvestajClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FRadnikID: Integer;
    FZaduzenjeID: Integer;
    procedure ResetStatusKrugove;
  public
  procedure SetRadnikID(ARadnikID: Integer);
    procedure LoadUputstvo(AZaduzenjeID, ARadnikID: Integer);
  end;

var
  Uputstvo: TUputstvo;

implementation
uses Unit1, Unit3;
{$R *.fmx}

procedure TUputstvo.ResetStatusKrugove;
begin
  ellZapoceo.Fill.Color := TAlphaColors.Lightgray;
  ellUToku.Fill.Color := TAlphaColors.Lightgray;
  ellZavrseno.Fill.Color := TAlphaColors.Lightgray;
end;

procedure TUputstvo.LoadUputstvo(AZaduzenjeID, ARadnikID: Integer);
begin
  FZaduzenjeID := AZaduzenjeID;
  FRadnikID := ARadnikID; // čuvanje radnika za kreiranje izveštaja
  ResetStatusKrugove;
  Memo1.Lines.Clear;
  Memo2.Lines.Clear;
  ListView1.Items.Clear;

  FDQuery1.Connection := Login.FDConnection1;

  // Receptura proizvoda
  FDQuery1.SQL.Text :=
    'SELECT p.Receptura ' +
    'FROM Proizvod p ' +
    'JOIN ProizvodniNalog pn ON p.ProizvodID = pn.ProizvodID ' +
    'JOIN Zaduzenje z ON z.NalogID = pn.NalogID ' +
    'WHERE z.ZaduzenjeID = :ZID';
  FDQuery1.ParamByName('ZID').AsInteger := AZaduzenjeID;
  FDQuery1.Open;
  if not FDQuery1.IsEmpty then
    Memo1.Lines.Text := FDQuery1.FieldByName('Receptura').AsString;
  FDQuery1.Close;

  // Lista sirovina sa stvarnom potrošnjom
  FDQuery1.SQL.Text :=
    'SELECT s.Naziv, r.Kolicina * pn.Kolicina AS Potrosnja, s.JedinicaMere ' +
    'FROM Receptura r ' +
    'JOIN Sirovina s ON r.SirovinaID = s.SirovinaID ' +
    'JOIN ProizvodniNalog pn ON r.ProizvodID = pn.ProizvodID ' +
    'JOIN Zaduzenje z ON z.NalogID = pn.NalogID ' +
    'WHERE z.ZaduzenjeID = :ZID';
  FDQuery1.ParamByName('ZID').AsInteger := AZaduzenjeID;
  FDQuery1.Open;

  ListView1.Items.Clear;
  while not FDQuery1.Eof do
  begin
    with ListView1.Items.Add do
    begin
      Text := FDQuery1.FieldByName('Naziv').AsString;
      Detail := FDQuery1.FieldByName('Potrosnja').AsString + ' ' +
                FDQuery1.FieldByName('JedinicaMere').AsString;
    end;
    FDQuery1.Next;
  end;
  FDQuery1.Close;

  // Uputstvo faze
  FDQuery1.SQL.Text :=
    'SELECT f.Uputstvo ' +
    'FROM Faza f ' +
    'JOIN Zaduzenje z ON f.FazaID = z.FazaID ' +
    'WHERE z.ZaduzenjeID = :ZID';
  FDQuery1.ParamByName('ZID').AsInteger := AZaduzenjeID;
  FDQuery1.Open;
  if not FDQuery1.IsEmpty then
    Memo2.Lines.Text := FDQuery1.FieldByName('Uputstvo').AsString;
  FDQuery1.Close;
end;

procedure TUputstvo.btnZapocniClick(Sender: TObject);
begin
  ellZapoceo.Fill.Color := TAlphaColors.Red;
  ellUToku.Fill.Color := TAlphaColors.Lightgray;
  ellZavrseno.Fill.Color := TAlphaColors.Lightgray;

  btnZapocni.Enabled := False;
  btnZavrsi.Enabled := True;

  // Upis pocetka u bazu
  FDQuery1.Connection := Login.FDConnection1;
  FDQuery1.SQL.Text := 'UPDATE Zaduzenje SET Pocetak = :Pocetak, Status = :Status WHERE ZaduzenjeID = :ZID';
  FDQuery1.ParamByName('Pocetak').AsDateTime := Now;
  FDQuery1.ParamByName('Status').AsString := 'U toku';
  FDQuery1.ParamByName('ZID').AsInteger := FZaduzenjeID;
  FDQuery1.ExecSQL;

  // Timer za "U toku"
  TimerUToku.Interval := 2000;
  TimerUToku.Enabled := True;
end;

procedure TUputstvo.TimerUTokuTimer(Sender: TObject);
begin
  ellUToku.Fill.Color := TAlphaColors.Yellow;
  TimerUToku.Enabled := False;
end;

procedure TUputstvo.btnZavrsiClick(Sender: TObject);
begin
  ellZavrseno.Fill.Color := TAlphaColors.Green;
  btnZavrsi.Enabled := False;

  // Upis zavrsetka u bazu
  FDQuery1.Connection := Login.FDConnection1;
  FDQuery1.SQL.Text := 'UPDATE Zaduzenje SET Kraj = :Kraj, Status = :Status WHERE ZaduzenjeID = :ZID';
  FDQuery1.ParamByName('Kraj').AsDateTime := Now;
  FDQuery1.ParamByName('Status').AsString := 'Završeno';
  FDQuery1.ParamByName('ZID').AsInteger := FZaduzenjeID;
  FDQuery1.ExecSQL;
end;
procedure TUputstvo.FormCreate(Sender: TObject);
begin
// Pastelno ljubičasta (#E5BDF2) sa punom providnošću
  Self.Fill.Color := TAlphaColor($FFE5BDF2);
end;

procedure TUputstvo.SetRadnikID(ARadnikID: Integer);
begin
  FRadnikID := ARadnikID;
end;
procedure TUputstvo.btnKreirajIzvestajClick(Sender: TObject);
begin
   // Provera da li je RadnikID postavljen
  if FRadnikID = 0 then
  begin
    ShowMessage('Greška: RadnikID nije postavljen!');
    Exit;
  end;

  // Provera da li je ZaduzenjeID postavljen
  if FZaduzenjeID = 0 then
  begin
    ShowMessage('Greška: ZaduženjeID nije postavljen!');
    Exit;
  end;

  // Otvaranje forme Izvestaj
  Izvestaj.LoadIzvestaj(FZaduzenjeID, FRadnikID);
  Izvestaj.Show;
  Self.Hide;
end;

procedure TUputstvo.btnNazadClick(Sender: TObject);
begin
  DetaljiNaloga.Show;
  Self.Hide;
end;

end.





