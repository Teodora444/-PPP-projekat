unit Unit5;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Edit, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FireDAC.Comp.Client, Data.DB;

type
  TIzvestaj = class(TForm)
    Label1: TLabel; // Broj dobrih
    Label2: TLabel; // Broj odbacenih
    Label3: TLabel; // Problemi
    Edit1: TEdit;   // Broj dobrih
    Edit2: TEdit;   // Broj odbacenih
    Memo1: TMemo;   // Problemi
    Button1: TButton; // Pošalji izveštaj
    lblRadnikID: TLabel;
    lblZaduzenjeID: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    lvSirovine: TListView;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject); // Lista potrošenih sirovina

  private
    FZaduzenjeID: Integer;
    FRadnikID: Integer;

    function GetSirovinaID(const Naziv: string): Integer;
  public
   procedure LoadIzvestaj(AZaduzenjeID, ARadnikID: Integer);
    { Public declarations }
  end;

var
  Izvestaj: TIzvestaj;

implementation
     uses Unit1,Unit3,Unit4;
{$R *.fmx}

procedure TIzvestaj.LoadIzvestaj(AZaduzenjeID, ARadnikID: Integer);
var
  i: Integer;
begin
  FZaduzenjeID := AZaduzenjeID;
  FRadnikID := ARadnikID;

  lblZaduzenjeID.Text := IntToStr(FZaduzenjeID);
  lblRadnikID.Text := IntToStr(FRadnikID);

  lvSirovine.Items.Clear;

  for i := 0 to Uputstvo.ListView1.Items.Count - 1 do
  begin
    with lvSirovine.Items.Add do
    begin
      Text := Uputstvo.ListView1.Items[i].Text;
      Detail := Uputstvo.ListView1.Items[i].Detail;
    end;
  end;
end;

procedure TIzvestaj.Button1Click(Sender: TObject);
var
  Q: TFDQuery;
  NoviIzvestajID, SirovinaID: Integer;
  i: Integer;
  Kolicina: Double;

  function ExistsInTable(const Table, Field: string; Value: Integer): Boolean;
  begin
    Q.SQL.Text := 'SELECT COUNT(*) AS C FROM ' + Table + ' WHERE ' + Field + ' = :Val';
    Q.ParamByName('Val').AsInteger := Value;
    Q.Open;
    Result := Q.FieldByName('C').AsInteger > 0;
    Q.Close;
  end;

begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := Login.FDConnection1;

    // 1️⃣ Provera ZaduzenjeID i RadnikID
    if not ExistsInTable('Zaduzenje', 'ZaduzenjeID', FZaduzenjeID) then
    begin
      ShowMessage('Greška: ZaduzenjeID ne postoji!');
      Exit;
    end;

    if not ExistsInTable('Radnik', 'RadnikID', FRadnikID) then
    begin
      ShowMessage('Greška: RadnikID ne postoji!');
      Exit;
    end;

    // 2️⃣ Ubacivanje osnovnog izveštaja
    Q.SQL.Text := 'INSERT INTO Izvestaj (ZaduzenjeID, RadnikID, BrojDobrih, BrojOdbacenih, Problemi, Datum) ' +
                  'VALUES (:ZID, :Rid, :BrojDobrih, :BrojOdbacenih, :Problemi, :Datum)';
    Q.ParamByName('ZID').AsInteger := FZaduzenjeID;
    Q.ParamByName('Rid').AsInteger := FRadnikID;
    Q.ParamByName('BrojDobrih').AsInteger := StrToIntDef(Edit1.Text, 0);
    Q.ParamByName('BrojOdbacenih').AsInteger := StrToIntDef(Edit2.Text, 0);
    Q.ParamByName('Problemi').AsString := Memo1.Lines.Text;
    Q.ParamByName('Datum').AsDateTime := Now;
    Q.ExecSQL;

    // Dobij ID poslednjeg ubačenog izveštaja
    Q.SQL.Text := 'SELECT last_insert_rowid() AS ID';
    Q.Open;
    NoviIzvestajID := Q.FieldByName('ID').AsInteger;
    Q.Close;

    // 3️⃣ Ubacivanje potrošenih sirovina
    for i := 0 to lvSirovine.Items.Count - 1 do
    begin
      Kolicina := StrToFloatDef(Copy(lvSirovine.Items[i].Detail, 1, Pos(' ', lvSirovine.Items[i].Detail)-1), 0);

      // Provera da li sirovina postoji
      SirovinaID := GetSirovinaID(lvSirovine.Items[i].Text);
      if SirovinaID = 0 then
      begin
        Continue; // preskoči ovu stavku
      end;

      Q.SQL.Text := 'INSERT INTO Utrosak (IzvestajID, SirovinaID, Kolicina) ' +
                    'VALUES (:IzvID, :Sid, :Kol)';
      Q.ParamByName('IzvID').AsInteger := NoviIzvestajID;
      Q.ParamByName('Sid').AsInteger := SirovinaID;
      Q.ParamByName('Kol').AsFloat := Kolicina;
      Q.ExecSQL;
    end;

    ShowMessage('Izveštaj je uspešno poslat.');
    Self.Hide;
    DetaljiNaloga.Show;

  finally
    Q.Free;
  end;
end;



procedure TIzvestaj.FormCreate(Sender: TObject);
begin
// Pastelno ljubičasta (#E5BDF2) sa punom providnošću
  Self.Fill.Color := TAlphaColor($FFE5BDF2);
end;

function TIzvestaj.GetSirovinaID(const Naziv: string): Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := Login.FDConnection1;
    Q.SQL.Text := 'SELECT SirovinaID FROM Sirovina WHERE TRIM(LOWER(Naziv)) = :Naziv';
    Q.ParamByName('Naziv').AsString := LowerCase(Trim(Naziv));
    Q.Open;
    if not Q.IsEmpty then
      Result := Q.FieldByName('SirovinaID').AsInteger;
    Q.Close;
  finally
    Q.Free;
  end;
end;

end.
