{ ============================================================================ }
{ DELPHI CONFERENCE 2012 - 23/10/2012                                          }
{ Jos� M�rio Silva Guedes - mario.guedes@arrayof.com.br                        }
{                                                                              }
{ Prop�sito: Oferecer classes de exe��o para a correta identifica��o dos       }
{            poss�veis erros                                                   }
{ ============================================================================ }

unit Unt_ClasseException;

interface

uses
  System.SysUtils,
  System.TypInfo;

type

  /// <summary>
  /// Caracteriza um erro de tipo de propriedade n�o previsto
  /// </summary>
  EGerarLinhaTipoNaoPrevisto = class(Exception)
  public
    constructor Create(ATipo: string);
  end;

implementation

{ EGerarLinhaTipoNaoPrevisto }

constructor EGerarLinhaTipoNaoPrevisto.Create(ATipo: string);
begin
  inherited Create(Format('Tipo de Propriedade n�o previsto: [%s]', [ATipo]));
end;

end.
