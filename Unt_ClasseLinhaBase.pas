unit Unt_ClasseLinhaBase;

interface

uses
  System.Classes;

type

  /// <summary>
  /// Classe base para a gera��o de uma determinada linha
  /// </summary>
  TLinhaBase = class abstract(TObject)
  private const
    C_SEPARADOR = '|';
  public
    /// <summary>
    /// Fun��o que retorna uma string de acordo com os atributos persoanlizados
    /// </summary>
    /// <returns>
    /// Linha formatada de acordo com os atributos definidos
    /// </returns>
    function GerarLinha: string;
  end;

implementation

uses
  System.Rtti,
  System.TypInfo,
  System.RegularExpressions,
  System.SysUtils,
  Unt_ClassesAtributos,
  Unt_ClasseException;

{ TLinhaBase }

function TLinhaBase.GerarLinha: string;

  function _FormatarValor(AValorPuro: string; AAtributo: TCustomAttribute): string;
  var
    iTamanhoString  : Integer;
    iTamanhoDesejado: Integer;
  begin
    { A string pode ter qualquer tamanho at� um limite determinado. }
    if (AAtributo is TStringVariavelAttribute) then
    begin
      iTamanhoString := Length(AValorPuro);
      iTamanhoDesejado := TStringVariavelAttribute(AAtributo).TamanhoMaximo;
      if (iTamanhoString > iTamanhoDesejado) then
      begin
        Result := Copy(AValorPuro, 1, iTamanhoDesejado);
        Exit;
      end else begin
        Result := AValorPuro;
        Exit;
      end;
    end;

    { A string TEM que ter o tamanho determinado, se for menor, preenche-se que
      o caracter determinado }
    if (AAtributo is TStringFixaAttribute) then
    begin
      iTamanhoString := Length(AValorPuro);
      iTamanhoDesejado := TStringFixaAttribute(AAtributo).Tamanho;
      if (iTamanhoString > iTamanhoDesejado) then
      begin
        Result := Copy(AValorPuro, 1, iTamanhoDesejado);
        Exit;
      end else if (Length(AValorPuro) < iTamanhoDesejado) then
      begin
        Result := StringOfChar(TStringFixaAttribute(AAtributo).Preenchimento, iTamanhoDesejado - iTamanhoString) + AValorPuro;
        Exit;
      end else begin
        Result := AValorPuro;
        Exit;
      end;
    end;

    { A string deve estar no formato data }
    if (AAtributo is TDataAttribute) then
    begin
      Result := FormatDateTime('ddmmyyyy', StrToDateTimeDef(AValorPuro, Now));
      Exit;
    end;

    { A string deve estar no formato monet�rio, sem separador de casa decimal }
    if (AAtributo is TMonetarioAttribute) then
    begin
      Result := TRegEx.Replace(AValorPuro, FormatSettings.DecimalSeparator, EmptyStr, []);
      Exit;
    end;

    // Se chegou at� aqui � porque o atributo n�o foi previsto
    Result := AValorPuro;
  end;

const
  C_POSICAO_INVALIDA = -1;
var
  _ctx          : TRttiContext; // Framework RTTI
  _typ          : TRttiType; // Reflex�o de Tipo
  _pro          : TRttiProperty; // Reflex�o de Properiedade
  _val          : TValue; // Reflex�o para o valor da propriedade
  oAtt          : TCustomAttribute; // Atributo Personalizado
  aCampos       : TArray<string>; // Estrat�gia para ordenar as informa��es
  iBufferPosicao: Integer; // Guarda a posi��o do campo
  sBufferValor  : string; // Guarda o valor convertido para a string
begin
  Result := EmptyStr;

  // Inicializando o framework de RTTI
  _ctx := TRttiContext.Create;
  try

    // Recuperando as informa��es da classe da inst�ncia corrente (Self)
    _typ := _ctx.GetType(Self.ClassInfo);
    if (Assigned(_typ)) then
    begin

      // Recuperando os ATRIBUTOS PERSONALIZADOS da classe
      for oAtt in _typ.GetAttributes do
      begin
        if (oAtt is TCodigoLinhaAttribute) then
        begin
          Result := FormatFloat('000', TCodigoLinhaAttribute(oAtt).CodigoLinha) + Self.C_SEPARADOR;
          Continue;
        end;
      end;

      // Dimensionando o array de acordo com a quantidade de PROPRIEDADES PUBLICADAS
      SetLength(aCampos, Length(_typ.GetDeclaredProperties));

      // Recuperando as PROPRIEDADES PUBLICADAS da classe
      for _pro in _typ.GetDeclaredProperties do
      begin

        iBufferPosicao := C_POSICAO_INVALIDA;
        sBufferValor := EmptyStr;

        // Recuperando os ATRIBUTOS PERSONALIZADOS da propriedades
        for oAtt in _pro.GetAttributes do
        begin

          if (oAtt is TOrdemImpressaoAttribute) then
          begin
            iBufferPosicao := TOrdemImpressaoAttribute(oAtt).OrdemImpressao;
            Continue;
          end;

          if (oAtt is TFormatacaoAttribute) then
          begin
            // Recuperando o valor da propriedade corrente da inst�ncia
            _val := _pro.GetValue(Self);

            // Dando o tratamento adequado de acordo com o tipo da PROPRIEDADE
            if (_val.IsType<string>) then
            begin
              sBufferValor := _val.AsString
            end else if (_val.IsType<Integer>) then
            begin
              sBufferValor := IntToStr(_val.AsInteger)
            end else if (_val.IsType<Currency>) then
            begin
              sBufferValor := FloatToStr(_val.AsCurrency);
            end else if (_val.IsType<TDateTime>) then
            begin
              sBufferValor := DateTimeToStr(_val.AsType<TDateTime>);
            end else begin
              raise EGerarLinhaTipoNaoPrevisto.Create(string(_val.TypeInfo.Name));
            end;
          end;

          // Formatando, efetivamente, o valor de acordo com o ATRIBUTO PERSONALIZADO
          sBufferValor := _FormatarValor(sBufferValor, oAtt);
        end;

        // Em posse das informa��es tempor�rias, preenche a posi��o do array
        if (iBufferPosicao > C_POSICAO_INVALIDA) then
        begin
          aCampos[iBufferPosicao - 1] := sBufferValor;
        end;
      end;

      // Por fim, varre-se o array gerando a linha em quest�o
      for sBufferValor in aCampos do
      begin
        Result := Result + sBufferValor + Self.C_SEPARADOR;
      end;
    end;
  finally
    // Finalizando o framework de RTTI
    _ctx.Free;

    // Liberando array
    Finalize(aCampos);
  end;
end;

end.
