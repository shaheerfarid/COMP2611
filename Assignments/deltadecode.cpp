#include <iostream>
using namespace std;
// Decode delta-encoded array in-place:
// after the function returns, delta[] becomes the decoded array A[].
void DeltaDecoding(int delta[], int A_SIZE) {
    // A[0] = delta[0], so the first element stays unchanged.
    // For i >= 1: A[i] = A[i-1] + delta[i]
    for (int i = 1; i < A_SIZE; i++) {
        delta[i] = delta[i - 1] + delta[i];
        // overwrite delta[i] with decoded A[i]
    }
}

int main() {
    const int A_SIZE = 10;
    int delta[100];
    // delta[] can hold up to 100 elements
    // Read delta[] from standard input
    cout << "Please enter integers in delta array delta[] one by one, use [Enter] to split:" << endl;
    for (int i = 0; i < A_SIZE; i++) {
        cout << "delta[" << i << "]: ";
        cin >> delta[i];
    }
    // Decode in-place (delta[] becomes A[])
    DeltaDecoding(delta, A_SIZE);
    // Output the decoded array
    cout << "The decoded array A[] is: ";
    for (int i = 0; i < A_SIZE; i++) {
        cout << delta[i] << " ";
        // delta[i] now stores A[i]
    }
    cout << endl;
    return 0;
}
