library flow.force_print;

int fprinti = 0;

void fprint(value) => print('${++fprinti}: $value');