/* No-op hooks copied from the pinned errortrigger4 ISR header. */
#ifndef CALIPTRA_ABR_ISR_COMPAT_H
#define CALIPTRA_ABR_ISR_COMPAT_H

#define abr_error mldsa_error
#define abr_notif mldsa_notif

static inline void service_abr_error_intr(void) {return;}
static inline void service_abr_notif_intr(void) {return;}

#endif // CALIPTRA_ABR_ISR_COMPAT_H
