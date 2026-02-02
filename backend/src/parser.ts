import { DocumentAIField, ExtractedField, ExtractionResult } from './types';

const FIELD_ALIASES: Record<string, string[]> = {
  consumer_number: [
    'consumer number',
    'consumer no',
    'consumer no.',
    'consumer id',
    'consumer id.',
    'consumer_number',
    'consumer_no',
    'consumer_id',
    'उपभोक्ता संख्या',
    'उपभोक्ता नं',
    'उपभोक्ता नं.',
    'उपभोक्ता आईडी',
    'account number',
    'account no',
    'account no.',
    'account id',
    'account id.',
    'account_number',
    'account_no',
    'account_id',
    'खाता संख्या',
    'खाता नं',
    'खाता नं.',
    'connection number',
    'connection no',
    'connection no.',
    'connection_number',
    'connection_no',
  ],
  consumer_name: [
    'consumer name',
    'consumer',
    'name',
    'consumer_name',
    'उपभोक्ता का नाम',
    'उपभोक्ता नाम',
    'नाम',
    'customer name',
    'customer',
    'customer_name',
    'ग्राहक का नाम',
    'ग्राहक नाम',
  ],
  meter_number: [
    'meter number',
    'meter no',
    'meter no.',
    'meter id',
    'meter id.',
    'meter_number',
    'meter_no',
    'meter_id',
    'मीटर संख्या',
    'मीटर नं',
    'मीटर नं.',
    'मीटर आईडी',
    'meter serial',
    'meter serial number',
    'meter_serial',
    'meter_serial_number',
  ],
  date: [
    'date',
    'reading date',
    'bill date',
    'issue date',
    'reading_date',
    'bill_date',
    'issue_date',
    'दिनांक',
    'तारीख',
    'पठन दिनांक',
    'बिल दिनांक',
  ],
};

function normalizeFieldName(fieldName: string): string {
  return fieldName
    .toLowerCase()
    .trim()
    .replace(/[^\w\s\u0900-\u097F]/g, '')
    .replace(/\s+/g, '_');
}

function findFieldKey(normalizedName: string): string | null {
  for (const [key, aliases] of Object.entries(FIELD_ALIASES)) {
    for (const alias of aliases) {
      const normalizedAlias = normalizeFieldName(alias);
      if (normalizedName === normalizedAlias || normalizedName.includes(normalizedAlias) || normalizedAlias.includes(normalizedName)) {
        return key;
      }
    }
  }
  return null;
}

export function parseDocumentAIFields(fields: DocumentAIField[]): ExtractionResult {
  const result: ExtractionResult = {
    needs_review: [],
  };

  const fieldMap: Record<string, ExtractedField> = {};

  for (const field of fields) {
    const normalizedName = normalizeFieldName(field.fieldName);
    const fieldKey = findFieldKey(normalizedName);

    if (!fieldKey) {
      continue;
    }

    const value = field.fieldValue?.textContent?.trim() || '';
    const confidence = field.confidence || 0;

    if (!value) {
      continue;
    }

    if (!fieldMap[fieldKey] || fieldMap[fieldKey].confidence < confidence) {
      fieldMap[fieldKey] = {
        value,
        confidence,
      };
    }
  }

  for (const [key, field] of Object.entries(fieldMap)) {
    (result as any)[key] = field;
    if (field.confidence < 0.75) {
      result.needs_review.push(key);
    }
  }

  return result;
}


