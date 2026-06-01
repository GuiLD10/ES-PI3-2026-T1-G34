// Autor: Rafael Lanza de Queiroz
// RA: 22010825

export class ExchangeError extends Error {
  readonly statusCode: number;
  readonly field?: string;

  constructor(statusCode: number, message: string, field?: string) {
    super(message);
    this.name = "ExchangeError";
    this.statusCode = statusCode;
    this.field = field;
  }
}

export function buildExchangeErrorResponse(
  error: unknown,
  fallbackMessage: string,
) {
  if (error instanceof ExchangeError) {
    return {
      statusCode: error.statusCode,
      body: {
        success: false,
        message: error.message,
        field: error.field,
      },
    };
  }

  return {
    statusCode: 500,
    body: {
      success: false,
      message: fallbackMessage,
    },
  };
}
