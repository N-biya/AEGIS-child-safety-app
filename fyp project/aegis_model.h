// aegis_model.h
// Auto-generated — DO NOT EDIT
// AEGIS Stress Detection Model
// Trained on WESAD Dataset

#ifndef AEGIS_MODEL_H
#define AEGIS_MODEL_H

#include <math.h>

// ── Scaler values (from StandardScaler) ──
const float SCALER_MEANS[14] = {74.465832, 184.441867, 250.659631, 2.123437, 0.070621, 2.296201, -0.000070, 6.750639, 33.100928, 0.033815, -0.000008, 63.707377, 3.067457, 98.250677};

const float SCALER_STDS[14] = {7.276396, 42.750582, 61.407730, 2.760304, 0.102811, 2.913796, 0.001266, 3.060844, 1.446395, 0.027185, 0.000564, 0.934693, 2.973830, 31.300561};

// ── Feature order ──
// [0] hr_mean      [1] hrv         [2] rmssd
// [3] eda_mean     [4] eda_std     [5] eda_max
// [6] eda_slope    [7] spike_count
// [8] temp_mean    [9] temp_std    [10] temp_slope
// [11] acc_mean    [12] acc_std    [13] acc_max

// ── Scale one feature ──
float scaleFeature(float value, int idx) {
    return (value - SCALER_MEANS[idx]) / SCALER_STDS[idx];
}

// ── Decision Trees ──

int tree_0(float* f) {
    if (f[13] <= 0.623687) {
        if (f[10] <= -0.278933) {
            if (f[4] <= -0.516427) {
                if (f[11] <= 2.016830) {
                    return 0;
                } else {
                    return 1;
                }
            } else {
                if (f[0] <= -0.666764) {
                    return 0;
                } else {
                    if (f[9] <= 2.181701) {
                        if (f[7] <= -1.388715) {
                            return 0;
                        } else {
                            if (f[8] <= 0.787337) {
                                if (f[12] <= 0.439095) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        return 0;
                    }
                }
            }
        } else {
            if (f[2] <= 1.219667) {
                if (f[1] <= 2.817459) {
                    if (f[11] <= -1.214057) {
                        return 1;
                    } else {
                        if (f[11] <= 1.859280) {
                            if (f[12] <= -0.940998) {
                                return 1;
                            } else {
                                if (f[0] <= 0.160278) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            }
                        } else {
                            return 1;
                        }
                    }
                } else {
                    return 1;
                }
            } else {
                if (f[0] <= -1.406979) {
                    return 0;
                } else {
                    if (f[5] <= -0.681966) {
                        return 0;
                    } else {
                        if (f[8] <= 0.116143) {
                            if (f[3] <= -0.014709) {
                                return 1;
                            } else {
                                return 0;
                            }
                        } else {
                            return 0;
                        }
                    }
                }
            }
        }
    } else {
        if (f[0] <= -0.086498) {
            if (f[5] <= -0.492472) {
                return 0;
            } else {
                if (f[10] <= -0.218349) {
                    if (f[8] <= -0.635928) {
                        return 1;
                    } else {
                        return 1;
                    }
                } else {
                    return 0;
                }
            }
        } else {
            if (f[11] <= -0.909392) {
                return 0;
            } else {
                if (f[8] <= 1.320171) {
                    if (f[8] <= 0.735355) {
                        if (f[9] <= 0.882176) {
                            return 1;
                        } else {
                            return 1;
                        }
                    } else {
                        return 1;
                    }
                } else {
                    return 0;
                }
            }
        }
    }
}

int tree_1(float* f) {
    if (f[10] <= -0.126820) {
        if (f[12] <= 0.174150) {
            if (f[2] <= -0.232655) {
                if (f[0] <= 0.208029) {
                    if (f[11] <= -1.178938) {
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[5] <= -0.514266) {
                        if (f[11] <= 0.555610) {
                            if (f[6] <= -0.105537) {
                                return 0;
                            } else {
                                return 0;
                            }
                        } else {
                            return 1;
                        }
                    } else {
                        return 1;
                    }
                }
            } else {
                if (f[0] <= -0.626060) {
                    return 0;
                } else {
                    if (f[4] <= -0.549625) {
                        return 0;
                    } else {
                        if (f[9] <= 1.404763) {
                            if (f[8] <= 0.903992) {
                                if (f[1] <= 1.738258) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 0;
                            }
                        } else {
                            return 0;
                        }
                    }
                }
            }
        } else {
            if (f[13] <= -0.062823) {
                return 0;
            } else {
                if (f[8] <= 1.058918) {
                    if (f[9] <= 0.834825) {
                        if (f[2] <= -0.858613) {
                            return 1;
                        } else {
                            if (f[11] <= 1.164560) {
                                if (f[3] <= -0.540797) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                if (f[11] <= 1.205711) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    } else {
                        return 1;
                    }
                } else {
                    return 0;
                }
            }
        }
    } else {
        if (f[11] <= 1.515738) {
            if (f[6] <= 0.132280) {
                if (f[0] <= 3.408535) {
                    if (f[1] <= 1.130146) {
                        if (f[2] <= 0.312001) {
                            return 0;
                        } else {
                            if (f[8] <= -0.249579) {
                                if (f[5] <= -0.580279) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            } else {
                                if (f[8] <= -0.148020) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            }
                        }
                    } else {
                        if (f[8] <= 0.018141) {
                            if (f[3] <= -0.208652) {
                                return 1;
                            } else {
                                return 0;
                            }
                        } else {
                            return 0;
                        }
                    }
                } else {
                    return 1;
                }
            } else {
                if (f[8] <= 0.445251) {
                    if (f[6] <= 0.406494) {
                        if (f[3] <= -0.653977) {
                            return 0;
                        } else {
                            return 1;
                        }
                    } else {
                        if (f[4] <= 0.996262) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                } else {
                    if (f[1] <= -0.025098) {
                        if (f[0] <= -0.912044) {
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        return 0;
                    }
                }
            }
        } else {
            if (f[6] <= -0.220065) {
                return 0;
            } else {
                if (f[8] <= -0.083030) {
                    return 1;
                } else {
                    return 0;
                }
            }
        }
    }
}

int tree_2(float* f) {
    if (f[5] <= -0.495580) {
        if (f[1] <= 0.433098) {
            if (f[12] <= 1.167160) {
                if (f[12] <= 0.269828) {
                    if (f[4] <= -0.656384) {
                        if (f[1] <= -1.757023) {
                            return 0;
                        } else {
                            if (f[3] <= -0.652935) {
                                if (f[1] <= -1.740836) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 1;
                            }
                        }
                    } else {
                        return 0;
                    }
                } else {
                    if (f[12] <= 0.306627) {
                        return 1;
                    } else {
                        return 0;
                    }
                }
            } else {
                return 1;
            }
        } else {
            if (f[11] <= 1.593161) {
                if (f[6] <= -0.314845) {
                    return 1;
                } else {
                    if (f[7] <= 0.571529) {
                        if (f[1] <= 0.469762) {
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        if (f[3] <= -0.661630) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            } else {
                return 1;
            }
        }
    } else {
        if (f[8] <= 0.761872) {
            if (f[0] <= -0.632376) {
                if (f[9] <= 1.422066) {
                    if (f[4] <= -0.635083) {
                        return 0;
                    } else {
                        return 0;
                    }
                } else {
                    return 0;
                }
            } else {
                if (f[9] <= 1.617099) {
                    if (f[10] <= -1.784157) {
                        return 0;
                    } else {
                        if (f[8] <= 0.649077) {
                            if (f[2] <= -1.884605) {
                                return 0;
                            } else {
                                if (f[0] <= -0.418540) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        } else {
                            if (f[1] <= 0.079728) {
                                return 0;
                            } else {
                                return 1;
                            }
                        }
                    }
                } else {
                    if (f[6] <= -1.621583) {
                        return 0;
                    } else {
                        return 0;
                    }
                }
            }
        } else {
            if (f[12] <= 2.197819) {
                return 0;
            } else {
                return 1;
            }
        }
    }
}

int tree_3(float* f) {
    if (f[2] <= -0.242218) {
        if (f[5] <= -0.369502) {
            if (f[11] <= 2.030601) {
                if (f[13] <= -0.790907) {
                    if (f[0] <= 3.383595) {
                        if (f[3] <= -0.366651) {
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        return 1;
                    }
                } else {
                    if (f[4] <= -0.656384) {
                        if (f[2] <= -1.688849) {
                            return 1;
                        } else {
                            if (f[3] <= -0.708693) {
                                return 0;
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        if (f[2] <= -2.445455) {
                            return 0;
                        } else {
                            return 0;
                        }
                    }
                }
            } else {
                return 1;
            }
        } else {
            if (f[8] <= -0.093055) {
                if (f[1] <= 0.408296) {
                    return 1;
                } else {
                    return 0;
                }
            } else {
                if (f[0] <= 1.108453) {
                    return 0;
                } else {
                    return 1;
                }
            }
        }
    } else {
        if (f[3] <= -0.653366) {
            if (f[5] <= -0.667878) {
                return 0;
            } else {
                return 0;
            }
        } else {
            if (f[0] <= -0.666682) {
                if (f[2] <= 1.352109) {
                    if (f[7] <= -1.715422) {
                        return 0;
                    } else {
                        return 0;
                    }
                } else {
                    return 1;
                }
            } else {
                if (f[7] <= 0.571529) {
                    if (f[8] <= 1.058918) {
                        if (f[1] <= -0.393739) {
                            return 0;
                        } else {
                            if (f[10] <= 0.873098) {
                                if (f[5] <= 1.530276) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                if (f[4] <= -0.266309) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            }
                        }
                    } else {
                        if (f[9] <= -0.768262) {
                            return 0;
                        } else {
                            return 0;
                        }
                    }
                } else {
                    if (f[1] <= -0.456069) {
                        return 1;
                    } else {
                        if (f[10] <= 0.499485) {
                            if (f[7] <= 0.898236) {
                                if (f[12] <= -0.611270) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 1;
                            }
                        } else {
                            return 1;
                        }
                    }
                }
            }
        }
    }
}

int tree_4(float* f) {
    if (f[10] <= -0.278933) {
        if (f[12] <= -0.884478) {
            return 0;
        } else {
            if (f[8] <= 0.762304) {
                if (f[5] <= -0.533115) {
                    if (f[2] <= 0.419930) {
                        if (f[7] <= -1.552068) {
                            return 1;
                        } else {
                            return 0;
                        }
                    } else {
                        return 1;
                    }
                } else {
                    if (f[8] <= 0.465949) {
                        if (f[7] <= -0.735300) {
                            if (f[5] <= 1.704890) {
                                return 1;
                            } else {
                                return 1;
                            }
                        } else {
                            if (f[9] <= 0.414084) {
                                return 1;
                            } else {
                                if (f[7] <= -0.245239) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    } else {
                        if (f[6] <= 0.333148) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            } else {
                if (f[6] <= 2.113578) {
                    return 0;
                } else {
                    return 1;
                }
            }
        }
    } else {
        if (f[12] <= 0.708825) {
            if (f[6] <= 0.457749) {
                if (f[3] <= -0.412822) {
                    if (f[0] <= 3.408535) {
                        if (f[9] <= -0.212395) {
                            return 0;
                        } else {
                            if (f[6] <= 0.146083) {
                                if (f[13] <= -0.854620) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        return 1;
                    }
                } else {
                    if (f[6] <= -0.126888) {
                        if (f[11] <= -1.256543) {
                            return 1;
                        } else {
                            if (f[12] <= -0.955030) {
                                return 1;
                            } else {
                                if (f[1] <= -0.033678) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            }
                        }
                    } else {
                        if (f[0] <= 0.340272) {
                            if (f[1] <= 0.337951) {
                                return 0;
                            } else {
                                return 1;
                            }
                        } else {
                            if (f[8] <= 0.191272) {
                                return 1;
                            } else {
                                return 0;
                            }
                        }
                    }
                }
            } else {
                if (f[2] <= -0.581254) {
                    return 0;
                } else {
                    if (f[12] <= 0.198571) {
                        return 1;
                    } else {
                        return 0;
                    }
                }
            }
        } else {
            if (f[3] <= -0.651754) {
                return 0;
            } else {
                if (f[0] <= 0.622963) {
                    if (f[8] <= 0.068006) {
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    return 1;
                }
            }
        }
    }
}

int tree_5(float* f) {
    if (f[2] <= -0.394908) {
        if (f[7] <= 0.571529) {
            if (f[13] <= 2.289196) {
                if (f[12] <= -0.684015) {
                    if (f[8] <= 0.080119) {
                        return 0;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[4] <= -0.656384) {
                        return 0;
                    } else {
                        return 0;
                    }
                }
            } else {
                return 0;
            }
        } else {
            if (f[5] <= -0.469843) {
                if (f[8] <= -2.036536) {
                    return 0;
                } else {
                    return 0;
                }
            } else {
                return 1;
            }
        }
    } else {
        if (f[5] <= -0.673804) {
            if (f[9] <= 0.199462) {
                return 0;
            } else {
                if (f[3] <= -0.658283) {
                    return 0;
                } else {
                    return 1;
                }
            }
        } else {
            if (f[0] <= -0.610831) {
                if (f[11] <= 0.490058) {
                    return 0;
                } else {
                    if (f[8] <= -0.277767) {
                        return 1;
                    } else {
                        if (f[12] <= 0.843053) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            } else {
                if (f[9] <= 2.010778) {
                    if (f[5] <= -0.520790) {
                        if (f[9] <= 0.447948) {
                            if (f[3] <= -0.653977) {
                                return 0;
                            } else {
                                if (f[4] <= -0.247779) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            }
                        } else {
                            return 0;
                        }
                    } else {
                        if (f[3] <= -0.605192) {
                            return 0;
                        } else {
                            if (f[9] <= -0.600647) {
                                if (f[9] <= -0.629003) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                if (f[10] <= 0.358382) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    }
                } else {
                    return 0;
                }
            }
        }
    }
}

int tree_6(float* f) {
    if (f[0] <= -0.337138) {
        if (f[12] <= 0.531013) {
            if (f[10] <= -0.308925) {
                if (f[2] <= 1.122341) {
                    return 0;
                } else {
                    return 1;
                }
            } else {
                if (f[4] <= 0.243130) {
                    if (f[1] <= 1.175029) {
                        return 0;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[7] <= -1.388715) {
                        return 1;
                    } else {
                        if (f[12] <= -0.025320) {
                            return 0;
                        } else {
                            return 0;
                        }
                    }
                }
            }
        } else {
            return 1;
        }
    } else {
        if (f[2] <= -0.462350) {
            if (f[12] <= -0.935644) {
                return 1;
            } else {
                if (f[12] <= 1.275226) {
                    if (f[11] <= -1.318986) {
                        return 1;
                    } else {
                        if (f[10] <= -0.378465) {
                            if (f[13] <= -0.777111) {
                                return 1;
                            } else {
                                if (f[13] <= 1.113010) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            }
                        } else {
                            if (f[13] <= -0.691793) {
                                if (f[8] <= -1.369821) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                if (f[5] <= -0.748595) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            }
                        }
                    }
                } else {
                    return 1;
                }
            }
        } else {
            if (f[6] <= 0.225690) {
                if (f[12] <= 0.714086) {
                    if (f[12] <= -0.636516) {
                        if (f[1] <= -0.521724) {
                            return 0;
                        } else {
                            if (f[0] <= -0.194439) {
                                return 1;
                            } else {
                                return 1;
                            }
                        }
                    } else {
                        if (f[10] <= -0.647052) {
                            if (f[9] <= 2.124882) {
                                if (f[1] <= -0.541039) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 0;
                            }
                        } else {
                            if (f[6] <= -0.233021) {
                                if (f[5] <= 0.552191) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                if (f[1] <= 0.864674) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    }
                } else {
                    if (f[5] <= -0.682366) {
                        return 0;
                    } else {
                        if (f[4] <= 0.032036) {
                            if (f[7] <= -1.715422) {
                                return 1;
                            } else {
                                return 1;
                            }
                        } else {
                            if (f[5] <= -0.011946) {
                                return 0;
                            } else {
                                if (f[11] <= -0.617795) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            } else {
                if (f[0] <= 0.132806) {
                    if (f[0] <= 0.035722) {
                        if (f[13] <= -0.640911) {
                            return 0;
                        } else {
                            return 1;
                        }
                    } else {
                        return 0;
                    }
                } else {
                    if (f[10] <= 0.956110) {
                        if (f[13] <= -1.058620) {
                            return 1;
                        } else {
                            return 1;
                        }
                    } else {
                        return 1;
                    }
                }
            }
        }
    }
}

int tree_7(float* f) {
    if (f[0] <= -0.089171) {
        if (f[13] <= 0.796158) {
            if (f[1] <= 1.125723) {
                if (f[4] <= 0.228202) {
                    if (f[12] <= 1.111830) {
                        if (f[4] <= -0.672473) {
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        return 1;
                    }
                } else {
                    if (f[13] <= -0.706779) {
                        return 1;
                    } else {
                        if (f[5] <= 1.978471) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            } else {
                if (f[10] <= 0.726463) {
                    if (f[8] <= -0.204914) {
                        return 1;
                    } else {
                        if (f[7] <= -1.388715) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                } else {
                    return 1;
                }
            }
        } else {
            if (f[8] <= -0.098644) {
                if (f[11] <= 1.184782) {
                    return 1;
                } else {
                    return 1;
                }
            } else {
                if (f[2] <= 1.663090) {
                    return 0;
                } else {
                    return 1;
                }
            }
        }
    } else {
        if (f[3] <= -0.604825) {
            if (f[5] <= -0.673804) {
                return 0;
            } else {
                if (f[11] <= 0.571662) {
                    if (f[5] <= -0.671393) {
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    return 1;
                }
            }
        } else {
            if (f[2] <= -0.823050) {
                if (f[10] <= -0.849440) {
                    return 1;
                } else {
                    if (f[4] <= -0.470300) {
                        return 1;
                    } else {
                        if (f[4] <= -0.350077) {
                            return 0;
                        } else {
                            return 0;
                        }
                    }
                }
            } else {
                if (f[9] <= 1.721687) {
                    if (f[12] <= -0.287215) {
                        if (f[11] <= 0.177289) {
                            return 1;
                        } else {
                            if (f[2] <= -0.339947) {
                                return 0;
                            } else {
                                return 1;
                            }
                        }
                    } else {
                        if (f[6] <= 0.013322) {
                            if (f[9] <= -0.671161) {
                                return 0;
                            } else {
                                if (f[10] <= 0.285295) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            }
                        } else {
                            if (f[8] <= 1.288584) {
                                if (f[8] <= 0.012379) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 0;
                            }
                        }
                    }
                } else {
                    return 0;
                }
            }
        }
    }
}

int tree_8(float* f) {
    if (f[4] <= -0.432871) {
        if (f[8] <= 0.061409) {
            if (f[3] <= -0.656057) {
                if (f[3] <= -0.658366) {
                    return 0;
                } else {
                    return 0;
                }
            } else {
                if (f[11] <= -1.067992) {
                    return 0;
                } else {
                    if (f[9] <= -0.756234) {
                        return 0;
                    } else {
                        if (f[6] <= -0.150555) {
                            return 0;
                        } else {
                            if (f[13] <= 1.534748) {
                                if (f[11] <= 0.609601) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 1;
                            }
                        }
                    }
                }
            }
        } else {
            if (f[5] <= -0.458265) {
                if (f[12] <= -0.983479) {
                    return 0;
                } else {
                    return 0;
                }
            } else {
                if (f[10] <= -0.861627) {
                    return 1;
                } else {
                    return 0;
                }
            }
        }
    } else {
        if (f[0] <= -0.127759) {
            if (f[2] <= 0.151053) {
                if (f[8] <= -0.863188) {
                    return 1;
                } else {
                    if (f[8] <= 0.229874) {
                        if (f[3] <= 1.694834) {
                            return 0;
                        } else {
                            return 1;
                        }
                    } else {
                        return 0;
                    }
                }
            } else {
                if (f[6] <= -0.453230) {
                    if (f[1] <= 0.506755) {
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[8] <= 0.028194) {
                        if (f[10] <= 1.995961) {
                            return 1;
                        } else {
                            return 0;
                        }
                    } else {
                        if (f[4] <= 1.897249) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            }
        } else {
            if (f[8] <= 0.779992) {
                if (f[2] <= -0.621303) {
                    if (f[7] <= -0.081886) {
                        return 0;
                    } else {
                        return 1;
                    }
                } else {
                    if (f[1] <= -0.451000) {
                        return 1;
                    } else {
                        if (f[5] <= -0.545668) {
                            return 1;
                        } else {
                            if (f[6] <= -0.273636) {
                                if (f[9] <= 0.411153) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                if (f[8] <= 0.721642) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    }
                }
            } else {
                if (f[8] <= 0.806826) {
                    return 0;
                } else {
                    return 0;
                }
            }
        }
    }
}

int tree_9(float* f) {
    if (f[3] <= -0.488930) {
        if (f[1] <= 1.133432) {
            if (f[0] <= 2.879631) {
                if (f[11] <= 1.844196) {
                    if (f[3] <= -0.570232) {
                        return 0;
                    } else {
                        if (f[10] <= -0.820109) {
                            return 1;
                        } else {
                            if (f[0] <= 0.067277) {
                                return 0;
                            } else {
                                return 1;
                            }
                        }
                    }
                } else {
                    return 1;
                }
            } else {
                return 1;
            }
        } else {
            if (f[3] <= -0.691103) {
                return 0;
            } else {
                if (f[6] <= -0.052757) {
                    return 0;
                } else {
                    if (f[10] <= -0.040630) {
                        return 1;
                    } else {
                        return 1;
                    }
                }
            }
        }
    } else {
        if (f[8] <= 0.186087) {
            if (f[9] <= 1.583229) {
                if (f[7] <= -0.735300) {
                    if (f[11] <= 1.189132) {
                        if (f[10] <= 1.301970) {
                            if (f[6] <= -2.820965) {
                                return 0;
                            } else {
                                if (f[6] <= -0.860447) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        } else {
                            return 0;
                        }
                    } else {
                        if (f[0] <= -0.088153) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                } else {
                    if (f[0] <= -0.716705) {
                        return 0;
                    } else {
                        if (f[9] <= 0.837984) {
                            if (f[6] <= -1.226377) {
                                if (f[6] <= -1.365159) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                if (f[5] <= 1.282670) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        } else {
                            return 1;
                        }
                    }
                }
            } else {
                return 0;
            }
        } else {
            if (f[4] <= -0.029894) {
                if (f[11] <= -0.844970) {
                    return 1;
                } else {
                    return 0;
                }
            } else {
                if (f[6] <= -0.347036) {
                    if (f[8] <= 0.516708) {
                        return 0;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[10] <= -0.514147) {
                        if (f[8] <= 0.787769) {
                            return 1;
                        } else {
                            return 1;
                        }
                    } else {
                        if (f[7] <= 0.244822) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            }
        }
    }
}

int tree_10(float* f) {
    if (f[3] <= -0.486828) {
        if (f[11] <= 1.560912) {
            if (f[11] <= -0.249662) {
                if (f[3] <= -0.559901) {
                    return 0;
                } else {
                    if (f[4] <= -0.334976) {
                        if (f[5] <= -0.559053) {
                            return 1;
                        } else {
                            if (f[4] <= -0.656873) {
                                return 0;
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        return 1;
                    }
                }
            } else {
                if (f[3] <= -0.660072) {
                    return 0;
                } else {
                    if (f[0] <= -0.354062) {
                        return 0;
                    } else {
                        if (f[5] <= -0.659366) {
                            return 1;
                        } else {
                            if (f[7] <= -0.245239) {
                                return 0;
                            } else {
                                return 1;
                            }
                        }
                    }
                }
            }
        } else {
            if (f[12] <= 0.370628) {
                return 0;
            } else {
                return 1;
            }
        }
    } else {
        if (f[8] <= 0.580631) {
            if (f[2] <= -0.785749) {
                if (f[11] <= 0.291843) {
                    if (f[13] <= -0.982815) {
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[12] <= -0.998755) {
                        return 0;
                    } else {
                        return 0;
                    }
                }
            } else {
                if (f[12] <= 0.497673) {
                    if (f[9] <= 1.246474) {
                        if (f[6] <= -0.043234) {
                            if (f[10] <= -0.129836) {
                                if (f[5] <= -0.367087) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 0;
                            }
                        } else {
                            if (f[12] <= -0.935146) {
                                return 1;
                            } else {
                                return 1;
                            }
                        }
                    } else {
                        if (f[3] <= -0.274818) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                } else {
                    if (f[10] <= -1.373804) {
                        return 1;
                    } else {
                        if (f[11] <= 2.304996) {
                            return 1;
                        } else {
                            return 1;
                        }
                    }
                }
            }
        } else {
            if (f[5] <= 2.963054) {
                if (f[13] <= -1.053970) {
                    return 0;
                } else {
                    if (f[1] <= 0.112401) {
                        return 0;
                    } else {
                        if (f[8] <= 0.775210) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                }
            } else {
                return 1;
            }
        }
    }
}

int tree_11(float* f) {
    if (f[6] <= 0.138813) {
        if (f[1] <= -0.108860) {
            if (f[11] <= 1.830664) {
                if (f[5] <= -0.366082) {
                    if (f[5] <= -0.674686) {
                        return 0;
                    } else {
                        if (f[5] <= -0.669637) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                } else {
                    if (f[4] <= 1.507894) {
                        if (f[0] <= 0.403284) {
                            if (f[13] <= -1.075246) {
                                return 0;
                            } else {
                                return 0;
                            }
                        } else {
                            if (f[12] <= -0.676871) {
                                return 1;
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        return 1;
                    }
                }
            } else {
                return 1;
            }
        } else {
            if (f[12] <= 0.445350) {
                if (f[5] <= -0.517969) {
                    if (f[0] <= -0.594278) {
                        if (f[7] <= -1.388715) {
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        if (f[11] <= -0.255005) {
                            if (f[5] <= -0.574647) {
                                if (f[7] <= -1.062008) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 1;
                            }
                        } else {
                            return 1;
                        }
                    }
                } else {
                    if (f[3] <= 1.737661) {
                        if (f[0] <= -0.666682) {
                            if (f[6] <= 0.078184) {
                                if (f[2] <= 1.367816) {
                                    return 0;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 1;
                            }
                        } else {
                            if (f[0] <= 0.917380) {
                                if (f[13] <= -0.406874) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 1;
                            }
                        }
                    } else {
                        if (f[12] <= 0.050919) {
                            return 1;
                        } else {
                            return 0;
                        }
                    }
                }
            } else {
                if (f[6] <= -2.793039) {
                    return 0;
                } else {
                    if (f[13] <= 0.146059) {
                        return 0;
                    } else {
                        if (f[3] <= -0.666062) {
                            return 0;
                        } else {
                            if (f[9] <= 0.924102) {
                                if (f[10] <= 0.420601) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 0;
                            }
                        }
                    }
                }
            }
        }
    } else {
        if (f[1] <= -0.294090) {
            if (f[7] <= 0.244822) {
                return 0;
            } else {
                return 1;
            }
        } else {
            if (f[0] <= -0.656226) {
                return 0;
            } else {
                if (f[6] <= 0.142064) {
                    return 0;
                } else {
                    if (f[10] <= -0.117117) {
                        if (f[10] <= -2.393350) {
                            return 0;
                        } else {
                            if (f[3] <= -0.680057) {
                                return 0;
                            } else {
                                if (f[1] <= 0.062144) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    } else {
                        if (f[10] <= -0.102275) {
                            return 0;
                        } else {
                            if (f[8] <= 0.634587) {
                                if (f[3] <= -0.559300) {
                                    return 0;
                                } else {
                                    return 1;
                                }
                            } else {
                                return 0;
                            }
                        }
                    }
                }
            }
        }
    }
}

int tree_12(float* f) {
    if (f[5] <= -0.512481) {
        if (f[12] <= 0.845553) {
            if (f[1] <= 2.139567) {
                if (f[5] <= -0.567392) {
                    if (f[12] <= 0.531013) {
                        if (f[10] <= -0.229329) {
                            if (f[2] <= -1.683051) {
                                return 0;
                            } else {
                                return 0;
                            }
                        } else {
                            if (f[13] <= -1.086417) {
                                return 0;
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        return 0;
                    }
                } else {
                    if (f[1] <= 0.426540) {
                        if (f[5] <= -0.559053) {
                            return 1;
                        } else {
                            return 0;
                        }
                    } else {
                        if (f[7] <= -0.408593) {
                            return 0;
                        } else {
                            return 1;
                        }
                    }
                }
            } else {
                return 1;
            }
        } else {
            if (f[10] <= 0.209054) {
                return 1;
            } else {
                return 1;
            }
        }
    } else {
        if (f[8] <= 0.563174) {
            if (f[6] <= -0.025530) {
                if (f[10] <= -0.132036) {
                    if (f[4] <= -0.407396) {
                        if (f[2] <= -0.828602) {
                            return 0;
                        } else {
                            return 1;
                        }
                    } else {
                        if (f[2] <= -0.288728) {
                            return 0;
                        } else {
                            if (f[3] <= -0.024567) {
                                if (f[5] <= -0.049484) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 1;
                            }
                        }
                    }
                } else {
                    if (f[0] <= 0.044234) {
                        if (f[4] <= 0.234258) {
                            return 0;
                        } else {
                            if (f[10] <= 0.228512) {
                                return 1;
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        return 1;
                    }
                }
            } else {
                if (f[6] <= 0.023449) {
                    return 1;
                } else {
                    if (f[0] <= -0.856040) {
                        return 0;
                    } else {
                        if (f[10] <= 1.462024) {
                            if (f[0] <= -0.183125) {
                                return 1;
                            } else {
                                return 1;
                            }
                        } else {
                            return 1;
                        }
                    }
                }
            }
        } else {
            if (f[6] <= 0.707146) {
                if (f[8] <= 0.680938) {
                    return 0;
                } else {
                    if (f[12] <= -0.924835) {
                        return 0;
                    } else {
                        return 0;
                    }
                }
            } else {
                if (f[13] <= 1.259207) {
                    return 0;
                } else {
                    return 1;
                }
            }
        }
    }
}

int tree_13(float* f) {
    if (f[4] <= -0.504155) {
        if (f[0] <= 0.052508) {
            if (f[1] <= 1.047432) {
                if (f[11] <= 1.800537) {
                    return 0;
                } else {
                    return 1;
                }
            } else {
                if (f[8] <= -0.077730) {
                    return 1;
                } else {
                    return 0;
                }
            }
        } else {
            if (f[1] <= 0.590980) {
                if (f[5] <= -0.524537) {
                    if (f[1] <= -1.757023) {
                        return 0;
                    } else {
                        return 0;
                    }
                } else {
                    return 1;
                }
            } else {
                if (f[2] <= 1.348066) {
                    if (f[11] <= -0.963310) {
                        return 0;
                    } else {
                        if (f[9] <= -0.523309) {
                            return 1;
                        } else {
                            return 1;
                        }
                    }
                } else {
                    return 0;
                }
            }
        }
    } else {
        if (f[10] <= -0.153057) {
            if (f[9] <= 1.500346) {
                if (f[1] <= -0.445806) {
                    if (f[8] <= 0.517658) {
                        return 1;
                    } else {
                        return 0;
                    }
                } else {
                    if (f[8] <= 1.052724) {
                        if (f[3] <= -0.512792) {
                            return 1;
                        } else {
                            if (f[0] <= -1.411948) {
                                return 0;
                            } else {
                                if (f[5] <= 0.843806) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        }
                    } else {
                        return 0;
                    }
                }
            } else {
                return 0;
            }
        } else {
            if (f[2] <= -0.298135) {
                if (f[8] <= -1.219102) {
                    return 1;
                } else {
                    if (f[7] <= 0.898236) {
                        return 0;
                    } else {
                        return 0;
                    }
                }
            } else {
                if (f[8] <= -0.339876) {
                    if (f[9] <= 1.062426) {
                        if (f[2] <= 0.110977) {
                            return 1;
                        } else {
                            return 1;
                        }
                    } else {
                        return 0;
                    }
                } else {
                    if (f[11] <= -1.048007) {
                        return 1;
                    } else {
                        if (f[8] <= -0.157468) {
                            return 0;
                        } else {
                            return 0;
                        }
                    }
                }
            }
        }
    }
}

int tree_14(float* f) {
    if (f[2] <= -0.242218) {
        if (f[13] <= 0.599444) {
            if (f[13] <= -1.106895) {
                return 1;
            } else {
                if (f[5] <= -0.369502) {
                    if (f[0] <= 3.408535) {
                        if (f[6] <= -1.199904) {
                            return 0;
                        } else {
                            return 0;
                        }
                    } else {
                        return 1;
                    }
                } else {
                    if (f[11] <= -1.208209) {
                        return 1;
                    } else {
                        if (f[9] <= -0.766306) {
                            return 1;
                        } else {
                            if (f[0] <= 2.094456) {
                                if (f[5] <= -0.364452) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 1;
                            }
                        }
                    }
                }
            }
        } else {
            if (f[6] <= 0.072375) {
                if (f[1] <= -0.441451) {
                    return 0;
                } else {
                    return 1;
                }
            } else {
                return 1;
            }
        }
    } else {
        if (f[3] <= -0.656675) {
            if (f[3] <= -0.657993) {
                return 0;
            } else {
                return 0;
            }
        } else {
            if (f[6] <= 0.017275) {
                if (f[3] <= -0.536748) {
                    if (f[11] <= 0.818450) {
                        if (f[13] <= 0.064192) {
                            return 0;
                        } else {
                            return 1;
                        }
                    } else {
                        return 1;
                    }
                } else {
                    if (f[8] <= 0.684049) {
                        if (f[10] <= 0.398930) {
                            if (f[0] <= -0.335830) {
                                return 0;
                            } else {
                                if (f[6] <= -0.085203) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        } else {
                            if (f[12] <= -0.525517) {
                                return 0;
                            } else {
                                return 0;
                            }
                        }
                    } else {
                        if (f[1] <= -0.357828) {
                            return 0;
                        } else {
                            return 0;
                        }
                    }
                }
            } else {
                if (f[0] <= -0.626060) {
                    if (f[2] <= 1.100248) {
                        return 0;
                    } else {
                        return 1;
                    }
                } else {
                    if (f[0] <= -0.459848) {
                        return 1;
                    } else {
                        if (f[8] <= 0.732071) {
                            if (f[7] <= -0.408593) {
                                if (f[9] <= 0.521607) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            } else {
                                if (f[3] <= 1.208225) {
                                    return 1;
                                } else {
                                    return 1;
                                }
                            }
                        } else {
                            return 1;
                        }
                    }
                }
            }
        }
    }
}

// ── Final Prediction (majority vote) ──
// Returns: 0 = NORMAL, 1 = STRESS
int aegis_predict(float* raw_features) {
    
    // Scale features
    float f[14];
    for (int i = 0; i < 14; i++) {
        f[i] = scaleFeature(raw_features[i], i);
    }
    
    // Collect votes from all trees
    int votes = 0;
    int n_trees = 15;
    
    votes += tree_0(f);
    votes += tree_1(f);
    votes += tree_2(f);
    votes += tree_3(f);
    votes += tree_4(f);
    votes += tree_5(f);
    votes += tree_6(f);
    votes += tree_7(f);
    votes += tree_8(f);
    votes += tree_9(f);
    votes += tree_10(f);
    votes += tree_11(f);
    votes += tree_12(f);
    votes += tree_13(f);
    votes += tree_14(f);

    // Majority vote
    return (votes > n_trees / 2) ? 1 : 0;
}

#endif // AEGIS_MODEL_H
