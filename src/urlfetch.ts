import axios from 'axios';

export function serialize(params: { [name: string]: { [name:string]: string | number | boolean } | string[] | string | number | boolean }): string {
  return Object.keys(params)
    .filter((name) => params[name] !== undefined)
    .map((name) => {
      const value = params[name];
      if (value === undefined) throw new Error('panic');
      if (value instanceof Array) {
        const list: string[] = [];
        for (const v of value) {
          list.push(encodeURIComponent(name) + '[]=' + encodeURIComponent(v));
        }
        return list.join('&');
      }
      if (typeof value === 'object') {
        const list: string[] = [];
        for (const k in value) {
          const v = value[k];
          if (v === undefined) throw new Error('panic');
          list.push(encodeURIComponent(name) + '[' + encodeURIComponent(k) + ']=' + encodeURIComponent(v));
        }
        return list.join('&');
      }
      return encodeURIComponent(name) + '=' + encodeURIComponent(value);
    })
    .join('&');
}

export function httpGet(url: string, headers: { [name: string]: string } = {}): Promise<string> {
  return new Promise((resolve, reject) => {
    axios.get(url, { headers, transformResponse: (data) => data })
      .then((response) => resolve(response.data))
      .catch((error) => reject(new Error(error.response.statusText)));
  });
}
