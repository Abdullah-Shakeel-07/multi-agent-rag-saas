import { redirect } from "next/navigation";

// No landing page — go straight to the dashboard (which redirects to /auth when signed out).
export default function Home() {
  redirect("/dashboard");
}
