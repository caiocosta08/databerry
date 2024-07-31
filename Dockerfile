
FROM node:18-alpine AS base
ARG SCOPE
ENV SCOPE=${SCOPE}


RUN npm --global install pnpm@8.7.5

RUN npm --global install turbo@2.0.9

FROM base AS pruner
WORKDIR /app
COPY . .
RUN pnpm install
RUN npx turbo prune --scope=dashboard --docker

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY .gitignore .gitignore
COPY .npmrc ./
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml

RUN pnpm install

RUN rm -rf node_modules/.pnpm/canvas@2.11.2

COPY --from=pruner /app/out/full/ .
COPY turbo.json turbo.json

ENV NEXT_TELEMETRY_DISABLED 1

ARG NEXT_PUBLIC_S3_BUCKET_NAME
ARG NEXT_PUBLIC_AWS_ENDPOINT
ARG NEXT_PUBLIC_DASHBOARD_URL
ARG NEXT_PUBLIC_SLACK_CLIENT_ID
ARG NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_STRIPE_PAYMENT_LINK_LEVEL_1
ARG NEXT_PUBLIC_STRIPE_PRICING_TABLE_ID
ARG NEXT_PUBLIC_CRISP_PLUGIN_ID
ARG NEXT_PUBLIC_GA_ID
ARG NEXT_PUBLIC_HOTJAR_ID
ARG NEXT_PUBLIC_FATHOM_SITE_ID
ARG NEXT_PUBLIC_POSTHOG_KEY
ARG NEXT_PUBLIC_POSTHOG_HOST
ARG NEXT_PUBLIC_MIXPANEL_TOKEN
ARG NEXT_PUBLIC_FACEBOOK_PIXEL_ID

RUN NODE_OPTIONS="--max_old_space_size=4096" pnpm turbo run build --filter=${SCOPE}...

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/apps/${SCOPE}/public ./apps/${SCOPE}/public
COPY --from=builder --chown=nextjs:nodejs /app/apps/${SCOPE}/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/${SCOPE}/.next/static ./apps/${SCOPE}/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/${SCOPE}/.next/server ./apps/${SCOPE}/.next/server

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD node apps/${SCOPE}/server.js