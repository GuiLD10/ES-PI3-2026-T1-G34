// Autor: Guilherme Lange Dallora
// RA: 23012353
// Descrição: converte valores do Firestore para resposta

type TimestampLike = {
  toDate: () => Date;
};

export function convertFirestoreValue(value: unknown): unknown {
  if (value === null || value === undefined) return value;
  if (typeof (value as TimestampLike).toDate === "function") {
    return (value as TimestampLike).toDate().toISOString();
  }
  if (Array.isArray(value)) return value.map(convertFirestoreValue);

  if (typeof value === "object") {
    const object: Record<string, unknown> = {};
    Object.entries(value as Record<string, unknown>).forEach(([key, item]) => {
      object[key] = convertFirestoreValue(item);
    });
    return object;
  }

  return value;
}
