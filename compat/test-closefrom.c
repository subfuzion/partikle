#include <unistd.h>

int main() {
    closefrom(3);
    return 0;
}
