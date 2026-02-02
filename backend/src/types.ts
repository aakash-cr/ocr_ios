export interface ExtractedField {
  value: string;
  confidence: number;
}

export interface ExtractionResult {
  consumer_number?: ExtractedField;
  consumer_name?: ExtractedField;
  meter_number?: ExtractedField;
  date?: ExtractedField;
  needs_review: string[];
}

export interface DocumentAIField {
  fieldName: string;
  fieldValue: {
    textAnchor?: {
      textSegments?: Array<{
        startIndex: string;
        endIndex: string;
      }>;
    };
    textContent?: string;
  };
  confidence: number;
}


