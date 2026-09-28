/**
 * Notification copy, in the three languages CTG uses.
 *
 * Every push notification is composed in the *recipient's* language
 * (users/{uid}.locale), never in the sender's - see docs/PLAN.md section 4.
 */
export type Locale = 'en' | 'fr' | 'ar';

type Template = Record<Locale, string>;

const STRINGS: Record<string, Template> = {
  taskAssignedTitle: {
    en: 'New task assigned',
    fr: 'Nouvelle tâche assignée',
    ar: 'مهمة جديدة مسندة إليك',
  },
  taskAssignedBody: {
    en: '{actor} assigned {key} to you: {title}',
    fr: '{actor} vous a assigné {key} : {title}',
    ar: 'أسند إليك {actor} المهمة {key}: {title}',
  },
  taskStatusTitle: {
    en: 'Task updated',
    fr: 'Tâche mise à jour',
    ar: 'تم تحديث المهمة',
  },
  taskStatusBody: {
    en: '{key} moved to {status}',
    fr: '{key} est passée à {status}',
    ar: 'انتقلت {key} إلى {status}',
  },
  taskDueSoonTitle: {
    en: 'Task due soon',
    fr: 'Tâche bientôt due',
    ar: 'مهمة قريبة الاستحقاق',
  },
  taskDueSoonBody: {
    en: '{key} is due within 24 hours: {title}',
    fr: '{key} est due dans moins de 24 heures : {title}',
    ar: 'تستحق {key} خلال 24 ساعة: {title}',
  },
  mentionTitle: {
    en: 'You were mentioned',
    fr: 'Vous avez été mentionné',
    ar: 'تمت الإشارة إليك',
  },
  messageBody: {
    en: '{actor} in {channel}: {text}',
    fr: '{actor} dans {channel} : {text}',
    ar: '{actor} في {channel}: {text}',
  },
  dmBody: {
    en: '{actor}: {text}',
    fr: '{actor} : {text}',
    ar: '{actor}: {text}',
  },
  eventInviteTitle: {
    en: 'New event',
    fr: 'Nouvel événement',
    ar: 'حدث جديد',
  },
  eventInviteBody: {
    en: '{actor} invited you to {title} on {date}',
    fr: '{actor} vous a invité à {title} le {date}',
    ar: 'دعاك {actor} إلى {title} بتاريخ {date}',
  },
  attachmentFallback: {
    en: 'sent an attachment',
    fr: 'a envoyé une pièce jointe',
    ar: 'أرسل مرفقًا',
  },
};

const STATUS_LABELS: Record<string, Template> = {
  backlog: { en: 'Backlog', fr: 'Backlog', ar: 'قائمة الانتظار' },
  todo: { en: 'To do', fr: 'À faire', ar: 'للتنفيذ' },
  inProgress: { en: 'In progress', fr: 'En cours', ar: 'قيد التنفيذ' },
  review: { en: 'Review', fr: 'Revue', ar: 'قيد المراجعة' },
  done: { en: 'Done', fr: 'Terminé', ar: 'منجزة' },
  blocked: { en: 'Blocked', fr: 'Bloqué', ar: 'متوقفة' },
};

export function normalizeLocale(value: unknown): Locale {
  return value === 'fr' || value === 'ar' ? value : 'en';
}

export function t(
  key: keyof typeof STRINGS | string,
  locale: Locale,
  params: Record<string, string> = {}
): string {
  const template = STRINGS[key];
  if (!template) return key;
  let out = template[locale] ?? template.en;
  for (const [name, value] of Object.entries(params)) {
    out = out.split(`{${name}}`).join(value);
  }
  return out;
}

export function statusLabel(status: string, locale: Locale): string {
  const template = STATUS_LABELS[status];
  return template ? template[locale] ?? template.en : status;
}

/** Locale-aware short date used in event notifications. */
export function formatDate(date: Date, locale: Locale): string {
  const tag = locale === 'ar' ? 'ar-MA' : locale === 'fr' ? 'fr-FR' : 'en-GB';
  return new Intl.DateTimeFormat(tag, {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}
