export class DateUtils {
  public static toCompactDate(d: Date): number {
    const y = d.getUTCFullYear();
    const m = d.getUTCMonth() + 1;
    const day = d.getUTCDate();
    return y * 10000 + m * 100 + day;
  }

  public static parseCompactDate(raw: number): { year: number; month: number; day: number } {
    const year = Math.floor(raw / 10000);
    const rem = raw % 10000;
    const month = Math.floor(rem / 100);
    const day = rem % 100;
    return { year, month, day };
  }

  public static getCutoffDate(currentDate: number, minAge: number): number {
    const { year, month, day } = this.parseCompactDate(currentDate);
    const cutoffYear = year - minAge;
    return cutoffYear * 10000 + month * 100 + day;
  }

  public static isEligible(birthDate: number, currentDate: number, minAge: number): boolean {
    const cutoff = this.getCutoffDate(currentDate, minAge);
    return birthDate <= cutoff;
  }
}
