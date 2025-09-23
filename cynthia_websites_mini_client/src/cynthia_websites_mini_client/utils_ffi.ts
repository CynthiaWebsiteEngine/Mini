export function getWindowHost() {
  return window.location.host;
}

export function compares(a: string, b: string): string {
  const result = a.localeCompare(b, undefined, { numeric: true });
  if (result < 0) {
    return "lt";
  } else if (result > 0) {
    return "gt";
  } else {
    return "eq";
  }
}

export function trims(str: string) {
  return str.trim();
}

export function set_theme_body(themename: string) {
  document.body.setAttribute("data-theme", themename);
}


export function whatever_timestamp_to_unix_millis(ts: string | number): number {
  if (typeof ts === "number") {
    // assume it's already unix millis
    return ts;
  } else if (typeof ts === "string") {
    // try to parse as ISO 8601 string
    const parsed = Date.parse(ts);
    if (!isNaN(parsed)) {
      return parsed;
    } else {
      throw new Error("Invalid timestamp string");
    }
  } else {
    throw new Error("Invalid timestamp type");
  }
}