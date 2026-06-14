export interface User {
  id: string;
  role: "user" | "manager";
}

/**
 * Apply a manager-only override discount. Authorization is enforced: a caller
 * who is not a manager is rejected before any discount is computed.
 * (Reference solution for the /selfcheck T2 security ticket.)
 */
export function applyManagerOverride(
  amount: number,
  percent: number,
  user: User,
): number {
  if (user.role !== "manager") {
    throw new Error("Unauthorized: manager role required");
  }
  const discounted = amount - amount * (percent / 100);
  return Math.round(discounted * 100) / 100;
}
