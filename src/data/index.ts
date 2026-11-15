import { demoRepository } from './demo/demoRepository';
import type { Repository } from './repository';

/**
 * The one place that decides where data comes from. Today: fictional data in memory.
 * When the backend exists, a Supabase implementation of Repository is swapped in here.
 */
export const repository: Repository = demoRepository;

export type { Repository } from './repository';
export * from './types';
