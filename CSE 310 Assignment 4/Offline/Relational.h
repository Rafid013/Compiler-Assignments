int relop(int i1, int i2, char *str) {
	int i;
	if(strcmp(str, "<") == 0) i = (i1 < i2);
	else if(strcmp(str, "<=") == 0) i = (i1 <= i2);
	else if(strcmp(str, ">") == 0) i = (i1 > i2);
	else if(strcmp(str, ">=") == 0) i = (i1 >= i2);
	else if(strcmp(str, "==") == 0) i = (i1 == i2);
	else i = (i1 != i2);
	return i;
}

int relop(int i1, float i2, char *str) {
	int i;
	if(strcmp(str, "<") == 0) i = (i1 < i2);
	else if(strcmp(str, "<=") == 0) i = (i1 <= i2);
	else if(strcmp(str, ">") == 0) i = (i1 > i2);
	else if(strcmp(str, ">=") == 0) i = (i1 >= i2);
	else if(strcmp(str, "==") == 0) i = (i1 == i2);
	else i = (i1 != i2);
	return i;
}


int relop(float i1, int i2, char *str) {
	int i;
	if(strcmp(str, "<") == 0) i = (i1 < i2);
	else if(strcmp(str, "<=") == 0) i = (i1 <= i2);
	else if(strcmp(str, ">") == 0) i = (i1 > i2);
	else if(strcmp(str, ">=") == 0) i = (i1 >= i2);
	else if(strcmp(str, "==") == 0) i = (i1 == i2);
	else i = (i1 != i2);
	return i;
}


int relop(float i1, float i2, char *str) {
	int i;
	if(strcmp(str, "<") == 0) i = (i1 < i2);
	else if(strcmp(str, "<=") == 0) i = (i1 <= i2);
	else if(strcmp(str, ">") == 0) i = (i1 > i2);
	else if(strcmp(str, ">=") == 0) i = (i1 >= i2);
	else if(strcmp(str, "==") == 0) i = (i1 == i2);
	else i = (i1 != i2);
	return i;
}
