unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Memo.Types, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.ScrollBox, FMX.Memo, FMX.Objects, Data.DB, FireDAC.Comp.Client,
  System.IOUtils;

type
  TDetaljiNaloga = class(TForm)
    imgProizvod: TImageControl;
    lblNalogID: TLabel;
    lblNazivProizvoda: TLabel;
    lblKolicina: TLabel;
    lblRok: TLabel;
    MemoReceptura: TMemo;
    lvFaze: TListView;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    btnNazad: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnNazadClick(Sender: TObject);
    procedure lvFazeItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure UputstvoButtonClick(Sender: TObject);
  private
    FRadnikID: Integer;
    FNalogID: Integer;
    FCurrentRadnikID: Integer;
    FSelectedZaduzenjeID: Integer;
    procedure ClearUputstvoButtons;
    function ButtonForFaza(FID: Integer): TButton;
    procedure UpdateUputstvoButton(FazaID, RadnikID: Integer);
    procedure UpdateUputstvoButtonTextColor(Btn: TButton; HasRight: Boolean);
  public
    procedure SetRadnikID(ARadnikID: Integer);
    procedure LoadNalog(ANalogID, ACurrentRadnikID: Integer);
  end;

var
  DetaljiNaloga: TDetaljiNaloga;

implementation

uses Unit1, Unit2, Unit4;

{$R *.fmx}

procedure TDetaljiNaloga.SetRadnikID(ARadnikID: Integer);
begin
  FRadnikID := ARadnikID;
end;
procedure TDetaljiNaloga.FormCreate(Sender: TObject);
begin
         // Pastelno ljubičasta (#E5BDF2) sa punom providnošću
  Self.Fill.Color := TAlphaColor($FFE5BDF2);
  FNalogID := 0;
  FCurrentRadnikID := 0;
  FSelectedZaduzenjeID := 0;
  ClearUputstvoButtons;

  // poveži sva dugmad na istu metodu
  Button1.OnClick := UputstvoButtonClick;
  Button2.OnClick := UputstvoButtonClick;
  Button3.OnClick := UputstvoButtonClick;
  Button4.OnClick := UputstvoButtonClick;
  Button5.OnClick := UputstvoButtonClick;
  Button6.OnClick := UputstvoButtonClick;
  Button7.OnClick := UputstvoButtonClick;
  Button8.OnClick := UputstvoButtonClick;
end;

procedure TDetaljiNaloga.ClearUputstvoButtons;
begin
  Button1.Visible := True;
  Button2.Visible := True;
  Button3.Visible := True;
  Button4.Visible := True;
  Button5.Visible := True;
  Button6.Visible := True;
  Button7.Visible := True;
  Button8.Visible := True;

  Button1.Tag := 0;
  Button2.Tag := 0;
  Button3.Tag := 0;
  Button4.Tag := 0;
  Button5.Tag := 0;
  Button6.Tag := 0;
  Button7.Tag := 0;
  Button8.Tag := 0;

  // reset boje
  UpdateUputstvoButtonTextColor(Button1, False);
  UpdateUputstvoButtonTextColor(Button2, False);
  UpdateUputstvoButtonTextColor(Button3, False);
  UpdateUputstvoButtonTextColor(Button4, False);
  UpdateUputstvoButtonTextColor(Button5, False);
  UpdateUputstvoButtonTextColor(Button6, False);
  UpdateUputstvoButtonTextColor(Button7, False);
  UpdateUputstvoButtonTextColor(Button8, False);
end;

function TDetaljiNaloga.ButtonForFaza(FID: Integer): TButton;
begin
  case FID of
    1: Result := Button1;
    2: Result := Button2;
    3: Result := Button3;
    4: Result := Button4;
    5: Result := Button5;
    6: Result := Button6;
    7: Result := Button7;
    8: Result := Button8;
  else
    Result := nil;
  end;
end;

procedure TDetaljiNaloga.UpdateUputstvoButtonTextColor(Btn: TButton; HasRight: Boolean);
begin
  if Btn = nil then Exit;
  Btn.StyledSettings := Btn.StyledSettings - [TStyledSetting.FontColor]; // ovo je ključno
  if HasRight then
    Btn.TextSettings.FontColor := TAlphaColorRec.Green
  else
    Btn.TextSettings.FontColor := TAlphaColorRec.Red;
end;


procedure TDetaljiNaloga.UpdateUputstvoButton(FazaID, RadnikID: Integer);
var
  Btn: TButton;
begin
  Btn := ButtonForFaza(FazaID);
  if Btn = nil then Exit;

  if RadnikID = FCurrentRadnikID then
  begin
    Btn.Tag := 1; // ima pravo
    UpdateUputstvoButtonTextColor(Btn, True);
  end
  else
  begin
    Btn.Tag := 0; // nema pravo
    UpdateUputstvoButtonTextColor(Btn, False);
  end;
end;

procedure TDetaljiNaloga.LoadNalog(ANalogID, ACurrentRadnikID: Integer);
var
  Q: TFDQuery;
  imgPath: string;
begin
  FNalogID := ANalogID;
  FCurrentRadnikID := ACurrentRadnikID;
  FSelectedZaduzenjeID := 0;

  ClearUputstvoButtons;
  lvFaze.Items.Clear;
  MemoReceptura.Lines.Clear;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := Login.FDConnection1;

    // učitavanje osnovnih podataka i recepture
    Q.SQL.Text :=
      'SELECT pn.NalogID, pn.ProizvodID, pn.Kolicina, pn.Rok, ' +
      'p.Naziv AS NazivProizvoda, p.Receptura AS RecepturaTekst, p.SlikaPath ' +
      'FROM ProizvodniNalog pn ' +
      'LEFT JOIN Proizvod p ON pn.ProizvodID = p.ProizvodID ' +
      'WHERE pn.NalogID = :NID';
    Q.ParamByName('NID').AsInteger := FNalogID;
    Q.Open;

    if not Q.IsEmpty then
    begin
      lblNalogID.Text := Q.FieldByName('NalogID').AsString;
      lblNazivProizvoda.Text := Q.FieldByName('NazivProizvoda').AsString;
      lblKolicina.Text := Q.FieldByName('Kolicina').AsString;
      lblRok.Text := Q.FieldByName('Rok').AsString;
      MemoReceptura.Lines.Text := Q.FieldByName('RecepturaTekst').AsString;

      imgPath := Q.FieldByName('SlikaPath').AsString;
      if (imgPath <> '') and FileExists(imgPath) then
        imgProizvod.Bitmap.LoadFromFile(imgPath)
      else
        imgProizvod.Bitmap := nil;
    end;
    Q.Close;

    // učitavanje faza
    Q.SQL.Text :=
      'SELECT z.ZaduzenjeID, z.FazaID, f.NazivFaze, z.RadnikID, ' +
      'COALESCE(r.Ime || '' '' || r.Prezime, '''') AS RadnikIme, ' +
      'COALESCE(z.Status, '''') AS Status, z.Pocetak, z.Kraj ' +
      'FROM Zaduzenje z ' +
      'LEFT JOIN Faza f ON z.FazaID = f.FazaID ' +
      'LEFT JOIN Radnik r ON z.RadnikID = r.RadnikID ' +
      'WHERE z.NalogID = :NID ORDER BY z.FazaID';
    Q.ParamByName('NID').AsInteger := FNalogID;
    Q.Open;

    while not Q.Eof do
    begin
      with lvFaze.Items.Add do
      begin
        Text := Q.FieldByName('NazivFaze').AsString;
        Detail := Q.FieldByName('RadnikIme').AsString;
        if Q.FieldByName('Status').AsString <> '' then
          Detail := Detail + ' | Status: ' + Q.FieldByName('Status').AsString;

        Tag := Q.FieldByName('ZaduzenjeID').AsInteger;

        UpdateUputstvoButton(Q.FieldByName('FazaID').AsInteger,
                             Q.FieldByName('RadnikID').AsInteger);

        if Q.FieldByName('RadnikID').AsInteger = FCurrentRadnikID then
          FSelectedZaduzenjeID := Q.FieldByName('ZaduzenjeID').AsInteger;
      end;
      Q.Next;
    end;

  finally
    Q.Free;
  end;
end;

procedure TDetaljiNaloga.lvFazeItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  if AItem = nil then Exit;
  FSelectedZaduzenjeID := AItem.Tag;
  // Primer za otvaranje uputstva
  Uputstvo.SetRadnikID(FCurrentRadnikID);
  Uputstvo.LoadUputstvo(FSelectedZaduzenjeID, FCurrentRadnikID);
  Uputstvo.Show;
  Self.Hide;
end;

procedure TDetaljiNaloga.UputstvoButtonClick(Sender: TObject);
var
  Btn: TButton;
begin
  Btn := Sender as TButton;
  if Btn.Tag = 1 then
  begin
    if FSelectedZaduzenjeID > 0 then
    begin
      Uputstvo.LoadUputstvo(FSelectedZaduzenjeID,FCurrentRadnikID);
      Uputstvo.Show;
      Self.Hide;
    end
    else
      ShowMessage('Nije izabrano zaduženje.');
  end
  else
    ShowMessage('❌ Nije ti dodeljena ova faza!');
end;

procedure TDetaljiNaloga.btnNazadClick(Sender: TObject);
begin
  Self.Hide;
  Home.Show;
end;

end.





