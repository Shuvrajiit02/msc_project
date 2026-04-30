#include <iostream>
#include <fstream>
#include <vector>
#include <map>
#include <cmath>

using namespace std;

int main()
{
    ifstream infile("data/mvs.txt");
    ofstream outfile("data/extracted_aux_bits.txt");

    if (!infile.is_open())
    {
        cerr << "Error opening mvs.txt\n";
        return -1;
    }

    vector<int> mvx_list;

    int frame, x, y, mvx, mvy;

    // -------------------------------
    // STEP 1: READ ALL MOTION VECTORS
    // -------------------------------
    while (infile >> frame >> x >> y >> mvx >> mvy)
    {
        mvx_list.push_back(mvx);
    }

    infile.close();

    if (mvx_list.empty())
    {
        cerr << "No motion vectors found\n";
        return -1;
    }

    // -------------------------------
    // STEP 2: BUILD HISTOGRAM
    // -------------------------------
    map<int, int> hist;

    for (int v : mvx_list)
    {
        hist[v]++;
    }

    // -------------------------------
    // STEP 3: FIND PEAK
    // -------------------------------
    int peak = 0;
    int max_count = 0;

    for (auto &p : hist)
    {
        if (p.second > max_count)
        {
            max_count = p.second;
            peak = p.first;
        }
    }

    cout << "[INFO] Detected peak: " << peak << endl;

    // -------------------------------
    // STEP 4: EXTRACT BITS
    // -------------------------------
    int bit_count = 0;

    for (int v : mvx_list)
    {
        if (v == peak)
        {
            outfile << 0 << "\n";
            bit_count++;
        }
        else if (v == peak + 1)
        {
            outfile << 1 << "\n";
            bit_count++;
        }
        // ignore others
    }

    outfile.close();

    cout << "[INFO] Extracted bits: " << bit_count << endl;
    cout << "Extracted bits saved to data/extracted_aux_bits.txt\n";

    return 0;
}