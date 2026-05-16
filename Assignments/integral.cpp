#include <iostream>
using namespace std;

int multiply(int a, int b)
{
    int result = 0;
    for (int i = 0; i < b; i++)
    {
        result = result + a;
    }
    return result;
}

void integral(const int A[], int S[], int N, int M)
{  
    //each row of the S[][] array has M+1 elements (i.e. 1 extra element more than A[][]), 
    //we need this to calculate for the S[i][j] address
    int SM = M + 1;

    // row 0, init row 0 of S[][] with 0’s
    for (int j = 0; j <= M; j++) S[j] = 0;
    // col 0, init col 0 of S[][] with 0’s
    for (int i = 0; i <= N; i++) S[multiply(i, SM)] = 0;

    for (int i = 1; i <= N; i++)
    {
        for (int j = 1; j <= M; j++)
        {
            // row major address calculation for A[i][j], note that i and j of A[][] both start from 1, NOT 0
            int aIdx   = multiply(i - 1, M)  + (j - 1);

            // row major calculation for the address of S[i][j]
            int sIdx   = multiply(i, SM)     + j;

           // row major calculation for the address of S[i-1][j]
           int upIdx  = multiply(i - 1, SM) + j;
          // row major calculation for the address of S[i][j-1]
           int leftIdx= multiply(i, SM)     + (j - 1);
          // row major calculation for the address of S[i-1][j-1]
           int diagIdx= multiply(i - 1, SM) + (j - 1);
           
           // calculate S[i][j]= A[i][j]+S[i-1][j]+S[i][j-1]-S[i-1][j-1] according to the equation
            S[sIdx] = A[aIdx] + S[upIdx] + S[leftIdx] - S[diagIdx];
        }
    }
}

void print2DMatrix(const int X[], int R, int C)
{
    for (int i = 0; i < R; i++)
    {
        for (int j = 0; j < C; j++)
        {
            if (j > 0) cout << " ";
            cout << X[multiply(i, C) + j];
        }
        cout << endl;
    }
}

int main()
{
    int N, M;

    cout << "Enter the number of rows N: ";
    cin >> N;
    cout << "Enter the number of columns M: ";
    cin >> M;

    int A[25];
    int S[36];

    cout << "Enter the input image A in row-major order:" << endl;
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < M; j++)
        {
            cout << "A[" << i + 1 << "][" << j + 1 << "]: ";
            cin >> A[multiply(i, M) + j];
        }
    }
    cout << "The initial matrix is " << endl;
    print2DMatrix(A, N, M);

    integral(A, S, N, M);

    cout << "Here is the integral image S:" << endl;
    print2DMatrix(S, N + 1, M + 1);

    return 0;
}
