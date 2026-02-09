import fs from "node:fs";
import path from "node:path";
import { List } from "../../../prelude.mjs";

export function exists(a: string): boolean {
	return fs.existsSync(a);
}

export function path_join(paths: List): string {
	return path.join(...paths.toArray());
}

export function path_normalize(p: string): string {
	return path.normalize(p);
}
