int f(int a){
    f(3);
    return 2*a;
    a=9;
}

int g(int a, int b){
    int x;
    x=f(a)+a+b;
    return x;
}

int main(){
    int a,b;
    a=1;
    b=2;
    a=f(a);
	h(3);
    println(a);
    return 0;
}


int h(int a) {return a;}
