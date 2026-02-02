# OCR Backend

Production-ready OCR backend using Google Document AI.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set environment variables:
```bash
export GCP_PROJECT_ID=your-project-id
export DOC_AI_PROCESSOR_ID=your-processor-id
export DOC_AI_LOCATION=us
```

3. Build:
```bash
npm run build
```

4. Run:
```bash
npm start
```

## Deploy to Cloud Run

```bash
gcloud run deploy ocr-backend \
  --source . \
  --platform managed \
  --region us-central1 \
  --set-env-vars GCP_PROJECT_ID=your-project-id,DOC_AI_PROCESSOR_ID=your-processor-id
```

## API

POST /extract
- Content-Type: multipart/form-data
- Body: file (image or PDF)
- Response: JSON with extracted fields and confidence scores


