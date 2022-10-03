export function hasProperty<K extends string | number | symbol>(value: NonNullable<object>, property: K): value is { [property in K]: unknown } {
  return property in value;
}

export function sleep(delay: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, delay));
}
