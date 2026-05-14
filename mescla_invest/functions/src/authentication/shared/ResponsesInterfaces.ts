import {StartupData} from "../../startups/types/StartupInterfaces";

export interface FirebaseLoginResponse {
  localId?: string;
  idToken?: string;
  error?: { message: string };
}

export interface ApiResponse {
  success: boolean;
  message?: string;
  uid?: string;
  token?: string;
  field?: string;
  data?: StartupData | StartupData[];
}
