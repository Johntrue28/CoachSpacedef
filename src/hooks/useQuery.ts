import { useCallback, useEffect, useState } from 'react';

import { repository } from '@/data';

interface QueryState<T> {
  data: T | undefined;
  loading: boolean;
  error: boolean;
  reload: () => void;
}

/**
 * Loads data from the repository and reloads it whenever the repository reports a change.
 * `key` identifies the query: pass a new key (for example an event id) to load something else.
 */
export function useQuery<T>(key: string, load: () => Promise<T>): QueryState<T> {
  const [state, setState] = useState<{ key: string; data?: T; error: boolean; loading: boolean }>({
    key,
    loading: true,
    error: false,
  });
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let active = true;
    const run = () => {
      load()
        .then((data) => {
          if (active) setState({ key, data, loading: false, error: false });
        })
        .catch(() => {
          if (active) setState({ key, loading: false, error: true });
        });
    };
    run();
    const unsubscribe = repository.subscribe(run);
    return () => {
      active = false;
      unsubscribe();
    };
    // `load` is recreated on every render; the key and the retry counter decide when to reload.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, attempt]);

  const reload = useCallback(() => setAttempt((value) => value + 1), []);
  const stale = state.key !== key;

  return { data: stale ? undefined : state.data, loading: stale || state.loading, error: !stale && state.error, reload };
}
