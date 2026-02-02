import { DocumentProcessorServiceClient } from '@google-cloud/documentai';
import { ExtractionResult, DocumentAIField } from './types';
import { parseDocumentAIFields } from './parser';

const PROJECT_ID = process.env.GCP_PROJECT_ID;
const PROCESSOR_ID = process.env.DOC_AI_PROCESSOR_ID;
const LOCATION = process.env.DOC_AI_LOCATION || 'us';

if (!PROJECT_ID || !PROCESSOR_ID) {
  throw new Error('GCP_PROJECT_ID and DOC_AI_PROCESSOR_ID must be set');
}

const client = new DocumentProcessorServiceClient();

const PROCESSOR_NAME = `projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}`;

function extractTextFromAnchor(document: any, textAnchor: any): string {
  if (!textAnchor || !textAnchor.textSegments || !document.text) {
    return '';
  }

  let fullText = '';
  for (const segment of textAnchor.textSegments) {
    const startIndex = parseInt(segment.startIndex || '0', 10);
    const endIndex = parseInt(segment.endIndex || '0', 10);
    if (startIndex >= 0 && endIndex <= document.text.length) {
      fullText += document.text.substring(startIndex, endIndex);
    }
  }
  return fullText.trim();
}

export async function extractFromDocument(fileBuffer: Buffer, mimeType: string): Promise<ExtractionResult> {
  const rawDocument = {
    content: fileBuffer,
    mimeType: mimeType,
  };

  const request = {
    name: PROCESSOR_NAME,
    rawDocument: rawDocument,
  };

  const [result] = await client.processDocument(request);
  const document = result.document;

  if (!document) {
    return { needs_review: [] };
  }

  const fields: DocumentAIField[] = [];

  if (document.pages && document.pages.length > 0) {
    for (const page of document.pages) {
      if (page.formFields) {
        for (const formField of page.formFields) {
          if (formField.fieldName && formField.fieldValue) {
            const fieldName = extractTextFromAnchor(document, formField.fieldName.textAnchor) || 
                            formField.fieldName.textContent || '';
            const fieldValue = extractTextFromAnchor(document, formField.fieldValue.textAnchor) || 
                             formField.fieldValue.textContent || '';
            const confidence = formField.fieldName.confidence || 
                             formField.fieldValue.confidence || 
                             (formField.fieldName.confidence && formField.fieldValue.confidence 
                               ? (formField.fieldName.confidence + formField.fieldValue.confidence) / 2 
                               : 0);

            if (fieldName && fieldValue) {
              fields.push({
                fieldName,
                fieldValue: {
                  textContent: fieldValue,
                },
                confidence,
              });
            }
          }
        }
      }
    }
  }

  return parseDocumentAIFields(fields);
}
