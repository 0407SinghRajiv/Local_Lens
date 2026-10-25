# Production Dockerfile for LocalLens Traveler Web (Next.js)
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package definitions for traveler-web
COPY traveler-web/package*.json ./
RUN npm install

# Copy application code
COPY traveler-web/ ./

# Build arguments for Next.js environment variables (provided at build time)
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG NEXT_PUBLIC_GOOGLE_MAPS_API_KEY
ARG NEXT_PUBLIC_OPENWEATHER_API_KEY
ARG NEXT_PUBLIC_GROQ_API_KEY

ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL} \
    NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL} \
    NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY} \
    NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=${NEXT_PUBLIC_GOOGLE_MAPS_API_KEY} \
    NEXT_PUBLIC_OPENWEATHER_API_KEY=${NEXT_PUBLIC_OPENWEATHER_API_KEY} \
    NEXT_PUBLIC_GROQ_API_KEY=${NEXT_PUBLIC_GROQ_API_KEY} \
    NODE_ENV=production

RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000

COPY --from=builder /app ./

EXPOSE 3000

CMD ["sh", "-c", "npx next start -p ${PORT:-3000}"]
