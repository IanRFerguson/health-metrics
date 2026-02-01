const isDevelopment = import.meta.env.DEV;
export const CACHE_DURATION_MS = isDevelopment ? 0.5 * 60 * 1000 : 15 * 60 * 1000; // 30 seconds in development, 15 minutes in production