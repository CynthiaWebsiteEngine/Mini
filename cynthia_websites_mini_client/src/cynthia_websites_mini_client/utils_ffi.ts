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