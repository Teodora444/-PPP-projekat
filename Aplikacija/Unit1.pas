unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Edit, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.FMXUI.Wait, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, FMX.Controls.Presentation,
  Unit2;


type
  TLogin = class(TForm)
    edtKorisnickoIme: TEdit;
    edtLozinka: TEdit;
    btnLogin: TButton;
    Label1: TLabel;
    lblPoruka: TLabel;
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
    procedure btnLoginClick(Sender: TObject);

  private
  public
  end;

var
  Login: TLogin;


implementation

{$R *.fmx}

procedure TLogin.btnLoginClick(Sender: TObject);
begin
  if (edtKorisnickoIme.Text = '') or (edtLozinka.Text = '') then
  begin
    lblPoruka.Text := 'Greška: Morate uneti korisničko ime i lozinku!';
    lblPoruka.TextSettings.FontColor := TAlphaColorRec.Navy;
    Exit;
  end;

  try
    FDConnection1.Connected := True; // Povezivanje na bazu

    FDQuery1.Close;
    FDQuery1.SQL.Text :=
      'SELECT * FROM Radnik WHERE KorisnickoIme = :KI AND Lozinka = :LO';
    FDQuery1.ParamByName('KI').AsString := edtKorisnickoIme.Text;
    FDQuery1.ParamByName('LO').AsString := edtLozinka.Text;
    FDQuery1.Open;

    if not FDQuery1.IsEmpty then
    begin
    Home.SetRadnikID(FDQuery1.FieldByName('RadnikID').AsInteger);
    // **Postavljanje konekcije iz Login-a u Home**
    Home.FDQueryRadnik.Connection := FDConnection1;
    Home.FDQueryNalozi.Connection := FDConnection1;
    Home.UcitajPodatke;
    Home.Show;
    Self.Hide;
    end
    else
    begin
      lblPoruka.Text := 'Pogrešno korisničko ime ili lozinka!';
      lblPoruka.TextSettings.FontColor := TAlphaColorRec.Navy;
    end;
  except
    on E: Exception do
      ShowMessage('Greška pri povezivanju: ' + E.Message);
  end;
end;



end.

