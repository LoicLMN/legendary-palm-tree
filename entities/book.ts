import { Chapter } from './chapter';
/*
export interface Book {
  id: string; // a guid
  title: string;
  chapters: Chapter[];
}
*/
export interface Book {
  id: string;
  title: string;
  link: string; 
  image: string;
  status: string;
  latest: string;
  type: string;
}